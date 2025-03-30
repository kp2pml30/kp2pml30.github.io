use std::sync::Arc;

struct ChallengeData {
    expires: chrono::DateTime<chrono::Utc>,
    challenge: altcha_lib_rs::Challenge,
}

pub struct Altcha {
    hmac_key: String,
    challenges: dashmap::DashMap<Arc<str>, ChallengeData>,
}

const ALLOWED_BYTES: &[u8] = b"1234567890!@#$%^&*()_+-=qwertyuiop[]asdfghjkl;'zxcvbnm,./QWERTYUIOPASDFGHJKLZXCVBNMN";

impl Altcha {
    pub fn new() -> anyhow::Result<Self> {
        let mut buf = [0;64];
        getrandom::fill(&mut buf).map_err(|_e| anyhow::anyhow!("can't get random"))?;

        for i in &mut buf {
            *i = ALLOWED_BYTES[(*i as usize) % ALLOWED_BYTES.len()];
        }

        Ok(Altcha {
            hmac_key: String::from_iter(buf.iter().map(|c| *c as char)),
            challenges: dashmap::DashMap::new(),
        })
    }
}

pub async fn challenge(zelf: Arc<Altcha>) -> anyhow::Result<String> {
    let wait_delta = chrono::TimeDelta::minutes(1);
    let std_delta = wait_delta.to_std()?;

    let expires = chrono::Utc::now() + wait_delta;
    let challenge = altcha_lib_rs::create_challenge(altcha_lib_rs::ChallengeOptions {
        hmac_key: &zelf.hmac_key,
        expires: Some(expires),
        ..Default::default()
    })?;

    let challenge_string = serde_json::to_string(&challenge)?;

    let uid: Arc<str> = Arc::from(challenge.salt.as_str());

    if let Some(_) = zelf.challenges.insert(uid.clone(), ChallengeData { expires: expires, challenge: challenge }) {
        anyhow::bail!("duplicate salt");
    }

    tokio::task::spawn(async move {
        tokio::time::sleep(tokio::time::Duration::from(std_delta)).await;
        zelf.challenges.remove(&uid);
    });

    Ok(challenge_string)
}

pub async fn verify(zelf: Arc<Altcha>, data: String) -> anyhow::Result<()> {
    let payload: altcha_lib_rs::Payload = serde_json::from_str(&data)?;

    let uid = &payload.salt;

    let data = match zelf.challenges.remove::<str>(uid) {
        None => {
            anyhow::bail!("no such challenge")
        }
        Some(data) => data.1,
    };

    if format!("{}", payload.algorithm) != format!("{}", data.challenge.algorithm) || payload.challenge != data.challenge.challenge {
        anyhow::bail!("data mismatch {:?} vs {:?}", payload, data.challenge);
    }

    if data.expires > chrono::Utc::now() {
        anyhow::bail!("expired");
    }

    altcha_lib_rs::verify_solution(&payload, &zelf.hmac_key, true)?;

    Ok(())
}
