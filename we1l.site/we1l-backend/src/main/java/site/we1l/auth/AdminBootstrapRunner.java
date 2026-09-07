package site.we1l.auth;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import site.we1l.entity.AdminUser;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 启动时初始化默认管理员账号：
 * - 表为空时，写入配置中的 ADMIN_USERNAME + ADMIN_PASSWORD（BCrypt 散列）
 * - 表已存在同名账号时，跳过（避免覆盖已修改的密码）
 * - 密码仅首次启动日志打印一次，提醒运维及时修改
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AdminBootstrapRunner implements CommandLineRunner {

    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final site.we1l.mapper.AdminUserMapper adminUserMapper;
    private final PasswordEncoder passwordEncoder;

    @Value("${we1l.auth.admin.username}")
    private String adminUsername;

    @Value("${we1l.auth.admin.password}")
    private String adminPassword;

    @Value("${we1l.auth.admin.display-name}")
    private String adminDisplayName;

    @Override
    public void run(String... args) {
        Long count = adminUserMapper.selectCount(Wrappers.<AdminUser>lambdaQuery());
        if (count != null && count > 0) {
            log.info("[Auth] admin_user 表已有 {} 条记录，跳过默认账号初始化", count);
            return;
        }
        AdminUser u = new AdminUser();
        u.setUsername(adminUsername);
        u.setPasswordHash(passwordEncoder.encode(adminPassword));
        u.setDisplayName(adminDisplayName);
        u.setRole("ADMIN");
        u.setStatus(1);
        u.setCreatedAt(DTF.format(LocalDateTime.now()));
        u.setUpdatedAt(u.getCreatedAt());
        adminUserMapper.insert(u);
        log.warn("[Auth] 已写入默认管理员账号：username={}  password={}（仅首次启动日志输出，请尽快登录后台修改！）",
                adminUsername, adminPassword);
    }
}
