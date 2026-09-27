package site.we1l.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Paths;

/**
 * 额外 Web 配置。
 *
 * 1) CORS 已移交给 site.we1l.auth.SecurityConfig（统一鉴权层管理），本类不再配置 CORS，
 *    否则会与 SecurityConfig 的 cors() 冲突（它从 CorsConfigurationSource bean 读取）。
 * 2) 此处把后台上传的图片目录映射为 /uploads/** 静态路径对外提供访问。
 *    映射路径与 SecurityConfig 的 anyRequest().permitAll() 一致 —— /uploads 不在
 *    /api/admin/** 之下，因此可被前台匿名读取（图片本身就是公开资源）。
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final String uploadDir;
    private final String urlPrefix;

    public WebConfig(@Value("${we1l.upload.dir}") String uploadDir,
                     @Value("${we1l.upload.url-prefix:/uploads}") String urlPrefix) {
        this.uploadDir = uploadDir;
        // 统一成 /xxx/** 形式，去掉结尾多余的斜杠
        String p = urlPrefix.endsWith("/") ? urlPrefix.substring(0, urlPrefix.length() - 1) : urlPrefix;
        this.urlPrefix = p.startsWith("/") ? p : "/" + p;
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String location = Paths.get(uploadDir).toAbsolutePath().normalize().toUri().toString();
        if (!location.endsWith("/")) {
            location = location + "/";
        }
        registry.addResourceHandler(urlPrefix + "/**").addResourceLocations(location);
    }
}
