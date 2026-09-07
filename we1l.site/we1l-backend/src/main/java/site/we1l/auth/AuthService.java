package site.we1l.auth;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import site.we1l.common.BusinessException;
import site.we1l.entity.AdminUser;
import site.we1l.mapper.AdminUserMapper;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 认证服务：登录/获取当前用户/默认账号初始化。
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final AdminUserMapper adminUserMapper;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    /** 登录：校验用户名+密码，签发 JWT，更新最后登录时间 */
    public TokenPair login(String username, String rawPassword) {
        if (username == null || rawPassword == null) {
            throw new BusinessException(400, "用户名或密码不能为空");
        }
        AdminUser user = adminUserMapper.selectOne(Wrappers.<AdminUser>lambdaQuery().eq(AdminUser::getUsername, username));
        if (user == null || user.getStatus() == null || user.getStatus() != 1) {
            throw new BusinessException(401, "账号或密码错误");
        }
        if (!passwordEncoder.matches(rawPassword, user.getPasswordHash())) {
            throw new BusinessException(401, "账号或密码错误");
        }
        // 更新最后登录时间
        user.setLastLoginAt(DTF.format(LocalDateTime.now()));
        adminUserMapper.updateById(user);

        String token = jwtUtil.issue(user.getUsername(), user.getRole());
        TokenPair pair = new TokenPair();
        pair.setToken(token);
        pair.setExpireSeconds(jwtUtil.getExpireSeconds());
        pair.setUser(toView(user));
        return pair;
    }

    public AdminUserView me(String username) {
        if (username == null) {
            throw new BusinessException(401, "未登录");
        }
        AdminUser user = adminUserMapper.selectOne(Wrappers.<AdminUser>lambdaQuery().eq(AdminUser::getUsername, username));
        if (user == null) {
            throw new BusinessException(401, "账号不存在");
        }
        return toView(user);
    }

    private AdminUserView toView(AdminUser u) {
        AdminUserView v = new AdminUserView();
        v.setId(u.getId());
        v.setUsername(u.getUsername());
        v.setDisplayName(u.getDisplayName());
        v.setRole(u.getRole());
        return v;
    }

    /** 登录结果 DTO */
    @lombok.Data
    public static class TokenPair {
        private String token;
        private long expireSeconds;
        private AdminUserView user;
    }

    /** 用户视图（不含敏感字段） */
    @lombok.Data
    public static class AdminUserView {
        private Long id;
        private String username;
        private String displayName;
        private String role;
    }
}
