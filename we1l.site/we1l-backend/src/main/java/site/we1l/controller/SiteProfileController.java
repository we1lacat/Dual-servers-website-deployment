package site.we1l.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import site.we1l.common.Result;
import site.we1l.entity.SiteProfile;
import site.we1l.service.SiteProfileService;

/**
 * 站点档案（站点名、站主信息、备案号、邮箱）。
 * 前台：GET /api/profile
 * 后台：PUT /api/admin/profile
 */
@RestController
@RequestMapping
@RequiredArgsConstructor
public class SiteProfileController {

    private final SiteProfileService siteProfileService;

    @GetMapping("/api/profile")
    public Result<SiteProfile> getProfile() {
        return Result.ok(siteProfileService.getProfile());
    }

    @PutMapping("/api/admin/profile")
    public Result<SiteProfile> saveProfile(@Valid @RequestBody SiteProfile form) {
        return Result.ok(siteProfileService.saveProfile(form));
    }
}
