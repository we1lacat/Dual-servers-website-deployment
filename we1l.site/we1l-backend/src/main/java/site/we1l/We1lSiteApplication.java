package site.we1l;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * we1l.site 后端启动类。
 */
@SpringBootApplication
@MapperScan("site.we1l.mapper")
public class We1lSiteApplication {

    public static void main(String[] args) {
        SpringApplication.run(We1lSiteApplication.class, args);
    }
}
