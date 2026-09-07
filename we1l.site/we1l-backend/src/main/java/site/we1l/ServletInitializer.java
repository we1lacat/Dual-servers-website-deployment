package site.we1l;

import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

/**
 * 外置 Tomcat（WAR 部署）入口。
 *
 * Spring Boot 打 WAR 丢进独立 Tomcat 时，不会执行 main()，
 * 而是通过 Servlet 3.0 的 ServletContainerInitializer SPI 启动，
 * 必须有这个类，否则 WAR 只会被解压、应用不会启动（全部接口 404）。
 *
 * 本地开发 `mvn spring-boot:run` / `java -jar` 走 main()，不受影响。
 */
public class ServletInitializer extends SpringBootServletInitializer {

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
        return application.sources(We1lSiteApplication.class);
    }
}
