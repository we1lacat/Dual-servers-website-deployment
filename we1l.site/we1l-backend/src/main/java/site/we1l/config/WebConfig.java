package site.we1l.config;

import org.springframework.context.annotation.Configuration;

/**
 * CORS 配置已移交给 site.we1l.auth.SecurityConfig（统一鉴权层管理）。
 * 保留本类作为占位，未来若需要支持 multipart 等额外跨域配置再加。
 */
@Configuration
public class WebConfig {

    // 注意：CORS 不再在此处配置，否则与 SecurityConfig 的 cors 配置冲突。
    //      spring-security 的 cors() 会从 CorsConfigurationSource bean 中读取。
}
