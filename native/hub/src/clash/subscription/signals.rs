// 订阅下载消息协议
//
// 目的：定义订阅下载的通信接口

use rinf::{DartSignal, RustSignal};
use serde::{Deserialize, Serialize};

// ============================================================================
// 订阅下载消息协议
// ============================================================================

// 代理模式枚举
#[derive(Deserialize, Serialize, Clone, Copy, Debug, rinf::SignalPiece)]
pub enum ProxyMode {
    Direct = 0, // 直连
    System = 1, // 系统代理
    Core = 2,   // Clash 核心代理
}

// Dart → Rust：下载订阅请求
#[derive(Deserialize, DartSignal)]
pub struct DownloadSubscriptionRequest {
    pub url: String,
    pub proxy_mode: ProxyMode,
    pub user_agent: String,
    pub timeout_seconds: u64,
    pub mixed_port: u16, // Clash 混合端口（用于 Core 代理模式）
}

// Rust → Dart：下载订阅响应
#[derive(Serialize, RustSignal)]
pub struct DownloadSubscriptionResponse {
    pub success: bool,
    pub content: String,                                 // 下载的配置内容
    pub subscription_info: Option<SubscriptionInfoData>, // 订阅信息
    pub error_message: Option<String>,
}

// 订阅信息数据
#[derive(Serialize, Deserialize, Clone, Debug, rinf::SignalPiece)]
pub struct SubscriptionInfoData {
    pub upload: Option<u64>,
    pub download: Option<u64>,
    pub total: Option<u64>,
    pub expire: Option<i64>, // Unix 时间戳
}

impl DownloadSubscriptionRequest {
    // 处理下载订阅请求
    pub async fn handle(self) {
        log::info!("收到下载订阅请求：{}", self.url);

        // 调用下载器
        let result = super::downloader::download_subscription(
            &self.url,
            self.proxy_mode,
            &self.user_agent,
            self.timeout_seconds,
            self.mixed_port,
        )
        .await;

        let response = match result {
            Ok((content, info)) => {
                log::info!("订阅下载成功，内容长度：{} 字节", content.len());
                DownloadSubscriptionResponse {
                    success: true,
                    content,
                    subscription_info: info,
                    error_message: None,
                }
            }
            Err(e) => {
                log::error!("订阅下载失败：{}", e);
                DownloadSubscriptionResponse {
                    success: false,
                    content: String::new(),
                    subscription_info: None,
                    error_message: Some(e.to_string()),
                }
            }
        };

        response.send_signal_to_dart();
    }
}
