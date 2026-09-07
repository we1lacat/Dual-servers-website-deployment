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
 * 前台：GET /api/trend
 * 后台：/api/admin/trend/**
 */
@RestController
@RequestMapping
@RequiredArgsConstructor
public class SiteTrendController {

    private final SiteTrendService siteTrendService;

    @GetMapping("/api/trend")
    public Result<List<SiteTrend>> list() {
        return Result.ok(siteTrendService.listForFront());
    }

    @GetMapping("/api/admin/trend/page")
    public Result<Page<SiteTrend>> page(@RequestParam(defaultValue = "1") long current,
                                        @RequestParam(defaultValue = "10") long size) {
        return Result.ok(siteTrendService.page(new Page<>(current, size), Wrappers.<SiteTrend>lambdaQuery()
                .orderByAsc(SiteTrend::getSortOrder)
                .orderByAsc(SiteTrend::getId)));
    }

    @PostMapping("/api/admin/trend")
    public Result<Boolean> create(@Valid @RequestBody SiteTrend entity) {
        return Result.ok(siteTrendService.create(entity));
    }

    @PutMapping("/api/admin/trend")
    public Result<Boolean> update(@Valid @RequestBody SiteTrend entity) {
        return Result.ok(siteTrendService.modify(entity));
    }

    @DeleteMapping("/api/admin/trend/{id}")
    public Result<Boolean> delete(@PathVariable Long id) {
        return Result.ok(siteTrendService.removeChecked(id));
    }
}
