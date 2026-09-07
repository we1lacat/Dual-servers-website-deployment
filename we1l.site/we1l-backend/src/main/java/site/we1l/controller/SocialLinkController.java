package site.we1l.controller;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import site.we1l.common.Result;
import site.we1l.entity.SocialLink;
import site.we1l.service.SocialLinkService;

import java.util.List;

/**
 * 「关于我」— 社交媒体矩阵。
 * 前台：GET /api/socials
 * 后台：/api/admin/socials/**
 */
@RestController
@RequestMapping
@RequiredArgsConstructor
public class SocialLinkController {

    private final SocialLinkService socialLinkService;

    @GetMapping("/api/socials")
    public Result<List<SocialLink>> list() {
        return Result.ok(socialLinkService.listEnabled());
    }

    @GetMapping("/api/admin/socials/page")
    public Result<Page<SocialLink>> page(@RequestParam(defaultValue = "1") long current,
                                         @RequestParam(defaultValue = "10") long size) {
        return Result.ok(socialLinkService.page(new Page<>(current, size), Wrappers.<SocialLink>lambdaQuery()
                .orderByAsc(SocialLink::getSortOrder)
                .orderByAsc(SocialLink::getId)));
    }

    @PostMapping("/api/admin/socials")
    public Result<Boolean> create(@Valid @RequestBody SocialLink entity) {
        if (entity.getStatus() == null) {
            entity.setStatus(1);
        }
        return Result.ok(socialLinkService.create(entity));
    }

    @PutMapping("/api/admin/socials")
    public Result<Boolean> update(@Valid @RequestBody SocialLink entity) {
        return Result.ok(socialLinkService.modify(entity));
    }

    @DeleteMapping("/api/admin/socials/{id}")
    public Result<Boolean> delete(@PathVariable Long id) {
        return Result.ok(socialLinkService.removeChecked(id));
    }
}
