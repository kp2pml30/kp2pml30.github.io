use std::{io::Write, sync::Arc};

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct CommentData {
    pub name: String,
    pub body: String,
    pub submitted: String,
}

pub struct Chatbox {
    db_path: tokio::sync::RwLock<String>,
}

impl Chatbox {
    pub fn new(db_path: String) -> Arc<Self> {
        Arc::new(Self {
            db_path: tokio::sync::RwLock::new(db_path),
        })
    }

    pub async fn add_message(&self, data: &CommentData) -> anyhow::Result<()> {
        let db_path = self.db_path.write().await;

        let mut file = std::fs::OpenOptions::new()
            .append(true)
            .create(true)
            .open(&*db_path)?;

        serde_json::to_writer(&file, &data)?;
        file.write_all(b"\n")?;

        file.flush()?;

        std::mem::drop(file);
        std::mem::drop(db_path);

        Ok(())
    }

    pub async fn get_all(&self) -> anyhow::Result<String> {
        let db_path = self.db_path.read().await;

        let result = tokio::fs::read_to_string(&*db_path).await?;

        std::mem::drop(db_path);

        Ok(result)
    }
}
