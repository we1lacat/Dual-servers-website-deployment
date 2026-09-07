package site.we1l.auth;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import site.we1l.common.Result;

/**
 * 认证接口（前+后端共用）：
 * - POST /api/auth/login         登录获取 JWT（公开）
 * - GET  /api/auth/me           解析 Authorization 返回当前用户（受 JWT 保护）
 * - POST /api/auth/logout       注销（无状态 JWT，此接口仅用于前端清理本地存储；返回 200）
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public Result<AuthService.TokenPair> login(@RequestBody LoginForm form) {
        return Result.ok(authService.login(form.getUsername(), form.getPassword()));
    }

    @GetMapping("/me")
    public Result<AuthService.AdminUserView> me() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getPrincipal() == null || "anonymousUser".equals(auth.getPrincipal())) {
            return Result.error(401, "未登录或登录已过期");
        }
        String username = auth.getName();
        return Result.ok(authService.me(username));
    }

    @PostMapping("/logout")
    public Result<Void> logout() {
        // JWT 无状态，注销由前端清除 localStorage 完成；后端清掉 SecurityContext
        SecurityContextHolder.clearContext();
        return Result.ok();
    }

    @Data
    public static class LoginForm {
        @NotBlank
        private String username;
        @NotBlank
        private String password;
    }
}
