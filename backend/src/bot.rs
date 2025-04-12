use std::sync::Arc;

use serde::{Deserialize, Serialize};
use teloxide::{dispatching::UpdateFilterExt, prelude::Requester, types::Message};

use crate::{cancellation, chatbox};

pub struct Bot {
    bot: teloxide::prelude::Bot,
    chatbox: Arc<chatbox::Chatbox>,
    kira_chat_id: teloxide::prelude::ChatId,
}

pub fn new(chatbox: Arc<chatbox::Chatbox>) -> anyhow::Result<Arc<Bot>> {
    let bot = teloxide::prelude::Bot::from_env();

    let id = std::env::var("KP2PML30_TG_CHAT_ID")?;

    return Ok(Arc::new(Bot {
        bot,
        chatbox,
        kira_chat_id: teloxide::types::ChatId(id.parse()?),
    }));
}

#[derive(Debug, Deserialize, Serialize)]
pub enum SendMsg {
    ApproveComment(chatbox::CommentData),
}

impl Bot {
    async fn repl_act_on(&self, msg: Message) -> anyhow::Result<()> {
        //self.bot.send_message(msg.chat.id, format!("Ok you are kira {}", msg.chat.id)).await?;

        let reply_to_text = match msg.reply_to_message().and_then(|x| x.text()) {
            None => anyhow::bail!("expected a reply"),
            Some(reply_to) => reply_to,
        };

        let kira_text = match msg.text() {
            None => anyhow::bail!("expected message with text"),
            Some(reply_to) => reply_to,
        };

        let req: SendMsg = serde_json::from_str(reply_to_text)?;

        match req {
            SendMsg::ApproveComment(approve_comment_payload) => {
                let approved: bool = serde_json::from_str(kira_text)?;

                if approved {
                    self.chatbox.add_message(&approve_comment_payload).await?;
                }
            }
        }

        Ok(())
    }
}

async fn loop_step(bot: Arc<Bot>, msg: Message) -> anyhow::Result<()> {
    if msg.chat.username() != Some("kp2pml30") {
        bot.bot
            .send_message(msg.chat.id, "You are not an authorized user")
            .await?;

        return Ok(());
    }

    let chat_id = msg.chat.id;

    log::info!(chat_id:? = chat_id; "received message from kira");

    if chat_id != bot.kira_chat_id {
        log::error!(chat_id:? = chat_id, kira_id:? = bot.kira_chat_id; "NOT KIRA ID");
    }

    if let Err(e) = bot.repl_act_on(msg).await {
        bot.bot
            .send_message(chat_id, format!("Error {:#}", e))
            .await?;
    }

    Ok(())
}

pub async fn start_loop(bot: Arc<Bot>, cancellation: Arc<cancellation::Token>) {
    use teloxide::dispatching::Dispatcher;
    let ignore_update = |_upd| Box::pin(async {});

    let bbot = bot.clone();
    let handler = move |_tbot: teloxide::prelude::Bot, msg| loop_step(bbot.clone(), msg);

    let mut dispatcher = Dispatcher::builder(
        bot.bot.clone(),
        teloxide::types::Update::filter_message().endpoint(handler),
    )
    .default_handler(ignore_update)
    .build();

    let shutdown = dispatcher.shutdown_token();

    let handle_shutdown = async move {
        cancellation.chan.closed().await;
        loop {
            if let Ok(f) = shutdown.shutdown() {
                f.await;
                break;
            }
        }
    };

    tokio::join!(
        handle_shutdown,
        dispatcher.dispatch_with_listener(
            teloxide::update_listeners::polling_default(bot.bot.clone()).await,
            teloxide::error_handlers::LoggingErrorHandler::with_custom_text(
                "An error from the update listener"
            ),
        ),
    );
}

impl Bot {
    pub async fn send_message(&self, data: &SendMsg) -> anyhow::Result<()> {
        log::info!(data:serde = data, chat_id:? = self.kira_chat_id; "sending message to kira");
        let msg = serde_json::to_string(&data)?;

        self.bot.send_message(self.kira_chat_id, msg).await?;

        Ok(())
    }
}
