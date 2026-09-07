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
import site.we1l.entity.LearningItem;
import site.we1l.service.LearningItemService;

import java.util.List;

/**
 * 「关于我」— 正在学习。
 * 前台：GET /api/learnings
 * 后台：/api/admin/learnings/**
 */
@RestController
@RequestMapping
@RequiredArgsConstructor
public class LearningItemController {

    private final LearningItemService learningItemService;

    @GetMapping("/api/learnings")
    public Result<List<LearningItem>> list() {
        return Result.ok(learningItemService.listEnabled());
    }

    @GetMapping("/api/admin/learnings/page")
    public Result<Page<LearningItem>> page(@RequestParam(defaultValue = "1") long current,
                                           @RequestParam(defaultValue = "10") long size) {
        return Result.ok(learningItemService.page(new Page<>(current, size), Wrappers.<LearningItem>lambdaQuery()
                .orderByAsc(LearningItem::getSortOrder)
                .orderByAsc(LearningItem::getId)));
    }

    @PostMapping("/api/admin/learnings")
    public Result<Boolean> create(@Valid @RequestBody LearningItem entity) {
        if (entity.getStatus() == null) {
            entity.setStatus(1);
        }
        return Result.ok(learningItemService.create(entity));
    }

    @PutMapping("/api/admin/learnings")
    public Result<Boolean> update(@Valid @RequestBody LearningItem entity) {
        return Result.ok(learningItemService.modify(entity));
    }

    @DeleteMapping("/api/admin/learnings/{id}")
    public Result<Boolean> delete(@PathVariable Long id) {
        return Result.ok(learningItemService.removeChecked(id));
    }
}
