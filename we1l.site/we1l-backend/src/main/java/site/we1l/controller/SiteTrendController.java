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
import site.we1l.entity.SiteTrend;
import site.we1l.service.SiteTrendService;

import java.util.List;

/**
 * 首页趋势数据。
 * 前台：GET /api/trends
 * 后台：/api/admin/trends/**
 *
 * 集合路径统一用复数，与 notes / works / resumes / learnings / skills / socials 保持一致；
 * 旧的单数路径 /api/trend 作为兼容别名保留（见 list()），便于前后端滚更期间不断链。
 */
@RestController
@RequestMapping
@RequiredArgsConstructor
public class SiteTrendController {

    private final SiteTrendService siteTrendService;

    /** 前台列表；同时兼容旧的单数路径 /api/trend */
    @GetMapping({"/api/trends", "/api/trend"})
    public Result<List<SiteTrend>> list() {
        return Result.ok(siteTrendService.listForFront());
    }

    @GetMapping("/api/admin/trends/page")
    public Result<Page<SiteTrend>> page(@RequestParam(defaultValue = "1") long current,
                                        @RequestParam(defaultValue = "10") long size) {
        return Result.ok(siteTrendService.page(new Page<>(current, size), Wrappers.<SiteTrend>lambdaQuery()
                .orderByAsc(SiteTrend::getSortOrder)
                .orderByAsc(SiteTrend::getId)));
    }

    @PostMapping("/api/admin/trends")
    public Result<Boolean> create(@Valid @RequestBody SiteTrend entity) {
        return Result.ok(siteTrendService.create(entity));
    }

    @PutMapping("/api/admin/trends")
    public Result<Boolean> update(@Valid @RequestBody SiteTrend entity) {
        return Result.ok(siteTrendService.modify(entity));
    }

    @DeleteMapping("/api/admin/trends/{id}")
    public Result<Boolean> delete(@PathVariable Long id) {
        return Result.ok(siteTrendService.removeChecked(id));
    }
}
