use std::{collections::HashMap, str::FromStr, sync::Arc};

use clap::Parser;
use warp::Filter;

mod altcha;

#[derive(clap::Parser)]
struct CliArgs {
    #[arg(long)]
    port: u16,

    #[arg(long, default_value_t = default_host())]
    host: String,

    #[arg(long, default_value_t = default_log_level())]
    log_level: log::LevelFilter,
}

#[derive(Debug)]
struct AnyhowErr(anyhow::Error);

impl warp::reject::Reject for AnyhowErr {}

fn default_host() -> String {
    return "127.0.0.1".to_owned();
}

fn default_log_level() -> log::LevelFilter {
    log::LevelFilter::Info
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let args = CliArgs::parse();

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

    let alt = Arc::new(altcha::Altcha::new()?);

    let alt1 = alt.clone();
    let challenge = warp::path!("altcha-challenge").and_then(move || {
        let alt1 = alt1.clone();
        async move {
            log::info!("/altcha-challenge");
            altcha::challenge(alt1).await.map_err(AnyhowErr).map_err(warp::reject::custom)
        }
    })
    .with(cors.clone());

    let alt1 = alt.clone();
    let post_blog = warp::path!("blog" / "comment")
        .and(warp::body::form::<HashMap<String, String>>())
        .and_then(move |mut form: HashMap<String, String>| {
            let alt1 = alt1.clone();
            async move {
                log::info!(body:? = form; "/blog/comment");
                let altcha_payload = form.remove("altcha").ok_or(anyhow::anyhow!("no capcha")).map_err(AnyhowErr)?;
                altcha::verify(alt1, altcha_payload.clone()).await.map_err(AnyhowErr)?;

                Ok(String::new()).map_err(|e| warp::reject::custom(AnyhowErr(e)))
            }
        })
        .with(cors);

    let routes_post = warp::post().and(post_blog);

    let routs_get = warp::get().and(challenge);

    log::info!("starting to serve");

    warp::serve(routes_post.or(routs_get)).run((host, args.port)).await;

    Ok(())
}
