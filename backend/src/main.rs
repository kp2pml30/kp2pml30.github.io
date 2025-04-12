use std::{str::FromStr, sync::Arc};

use anyhow::Context;
use clap::Parser;
use serde::{Deserialize, Serialize};
use warp::Filter;

mod altcha;
mod bot;
mod cancellation;
mod chatbox;

#[derive(clap::Parser)]
struct CliArgs {
    #[arg(long)]
    port: u16,

    #[arg(long, default_value_t = default_host())]
    host: String,

    #[arg(long, default_value_t = default_log_level())]
    log_level: log::LevelFilter,

    #[arg(long)]
    moderated_path: String,
}

struct AnyhowErr(anyhow::Error);

impl std::fmt::Debug for AnyhowErr {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_fmt(format_args!("{:#}", self.0))
    }
}

impl warp::reject::Reject for AnyhowErr {}

fn default_host() -> String {
    return "127.0.0.1".to_owned();
}

fn default_log_level() -> log::LevelFilter {
    log::LevelFilter::Info
}

#[derive(Debug, Deserialize, Serialize)]
struct CommentRequest {
    name: String,
    body: String,
    altcha: String,
}

async fn handle_post_comment(
    backend_ctx: Arc<BackendCtx>,
    form: CommentRequest,
) -> anyhow::Result<()> {
    log::info!(body:serde = form; "/blog/comment");
    backend_ctx
        .altcha
        .verify(form.altcha.clone())
        .await
        .with_context(|| "verifying capcha")?;

    if form.name.is_empty() || form.body.is_empty() {
        anyhow::bail!("required field is empty");
    }

    if form.name.len() > 512 || form.body.len() > 4096 {
        anyhow::bail!("too large")
    }

    backend_ctx
        .bot
        .send_message(&bot::SendMsg::ApproveComment(chatbox::CommentData {
            body: form.body,
            name: form.name,
            submitted: chrono::Utc::now().to_rfc3339(),
        }))
        .await?;

    Ok(())
}

struct BackendCtx {
    bot: Arc<bot::Bot>,
    chatbox: Arc<chatbox::Chatbox>,
    altcha: Arc<altcha::Altcha>,
}

#[tokio::main(flavor = "multi_thread", worker_threads = 2)]
async fn main() -> anyhow::Result<()> {
    let args = CliArgs::parse();

    let chatbox = chatbox::Chatbox::new(args.moderated_path.clone());

    let bot = bot::new(chatbox.clone())?;

    let backend_ctx = Arc::new(BackendCtx {
        chatbox,
        bot: bot.clone(),
        altcha: Arc::new(altcha::Altcha::new()?),
    });

    structured_logger::Builder::with_level(args.log_level.as_str())
        .with_default_writer(structured_logger::json::new_writer(std::io::stderr()))
        .init();

    #[cfg(debug_assertions)]
    let cors = warp::cors()
        .allow_any_origin()
        .allow_methods(vec!["GET", "POST"]);

    #[cfg(not(debug_assertions))]
    let cors = warp::cors()
        .allow_origin("https://kp2pml30.moe")
        .allow_methods(vec!["GET", "POST"]);

    let host = std::net::Ipv4Addr::from_str(&args.host)?;

    let ctx = backend_ctx.clone();
    let challenge = warp::path!("altcha-challenge")
        .and_then(move || {
            let ctx = ctx.clone();
            async move {
                log::info!("/altcha-challenge");
                altcha::challenge(ctx.altcha.clone())
                    .await
                    .map_err(AnyhowErr)
                    .map_err(warp::reject::custom)
            }
        })
        .with(cors.clone());

    let ctx = backend_ctx.clone();
    let post_blog = warp::path!("blog" / "comment")
        .and(warp::body::form::<CommentRequest>())
        .and_then(move |form: CommentRequest| {
            let ctx = ctx.clone();
            async move {
                handle_post_comment(ctx, form)
                    .await
                    .map_err(AnyhowErr)
                    .map_err(warp::reject::custom)?;
                Ok::<String, warp::Rejection>("{}".to_owned())
            }
        })
        .with(cors.clone());

    let ctx = backend_ctx.clone();
    let get_comments = warp::path!("blog" / "comment")
        .and_then(move || {
            let ctx = ctx.clone();
            async move {
                ctx.chatbox
                    .get_all()
                    .await
                    .map_err(AnyhowErr)
                    .map_err(warp::reject::custom)
            }
        })
        .with(cors);

    let routes_post = warp::post().and(post_blog);

    let routs_get = warp::get().and(challenge).or(get_comments);

    log::info!("starting to serve");

    let (cancel_tok, canceller) = cancellation::make();

    let handle_sigterm = move || {
        log::warn!("sigterm received");
        canceller();
    };
    unsafe {
        signal_hook::low_level::register(signal_hook::consts::SIGTERM, handle_sigterm.clone())?;
        signal_hook::low_level::register(signal_hook::consts::SIGINT, handle_sigterm)?;
    }

    let cancellation = cancel_tok.clone();
    let serve_bot = async move {
        bot::start_loop(bot.clone(), cancellation).await;
    };

    let cancellation = cancel_tok.clone();
    let serve_warp = async move {
        let serv = warp::serve(routes_post.or(routs_get));

        //let canc = cancel_tok.chan.closed();
        let (addr, fut) = serv.bind_with_graceful_shutdown((host, args.port), async move {
            cancellation.chan.closed().await
        });

        log::info!(address:? = addr; "listening on");

        fut.await;
    };

    tokio::join!(serve_bot, serve_warp,);

    Ok(())
}
