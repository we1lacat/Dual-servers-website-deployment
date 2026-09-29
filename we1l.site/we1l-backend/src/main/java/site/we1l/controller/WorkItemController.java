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
import site.we1l.entity.WorkItem;
import site.we1l.service.WorkItemService;

import java.util.List;

/**
 * 「服务」— 作品展示。
 * 前台：GET /api/works
 * 后台：/api/admin/works/**
 */
@RestController
@RequestMapping
@RequiredArgsConstructor
public class WorkItemController {

    private final WorkItemService workItemService;

    @GetMapping("/api/works")
    public Result<List<WorkItem>> list() {
        return Result.ok(workItemService.listEnabled());
    }

    @GetMapping("/api/admin/works/page")
    public Result<Page<WorkItem>> page(@RequestParam(defaultValue = "1") long current,
                                       @RequestParam(defaultValue = "10") long size) {
        return Result.ok(workItemService.page(new Page<>(current, size), Wrappers.<WorkItem>lambdaQuery()
                .orderByAsc(WorkItem::getSortOrder)
                .orderByAsc(WorkItem::getId)));
    }

    @PostMapping("/api/admin/works")
    public Result<Boolean> create(@Valid @RequestBody WorkItem entity) {
        if (entity.getStatus() == null) {
            entity.setStatus(1);
        }
        if (entity.getCover() == null) {
            entity.setCover("");
        }
        return Result.ok(workItemService.create(entity));
    }

    @PutMapping("/api/admin/works")
    public Result<Boolean> update(@Valid @RequestBody WorkItem entity) {
        return Result.ok(workItemService.modify(entity));
    }

    @DeleteMapping("/api/admin/works/{id}")
    public Result<Boolean> delete(@PathVariable Long id) {
        return Result.ok(workItemService.removeChecked(id));
    }
}
