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
import site.we1l.entity.ResumeTemplate;
import site.we1l.service.ResumeTemplateService;

import java.util.List;

/**
 * 「笔记 / 服务」— 简历模板。
 * 前台：GET /api/resumes
 * 后台：/api/admin/resumes/**
 */
@RestController
@RequestMapping
@RequiredArgsConstructor
public class ResumeTemplateController {

    private final ResumeTemplateService resumeTemplateService;

    @GetMapping("/api/resumes")
    public Result<List<ResumeTemplate>> list() {
        return Result.ok(resumeTemplateService.listEnabled());
    }

    @GetMapping("/api/admin/resumes/page")
    public Result<Page<ResumeTemplate>> page(@RequestParam(defaultValue = "1") long current,
                                             @RequestParam(defaultValue = "10") long size) {
        return Result.ok(resumeTemplateService.page(new Page<>(current, size),
                Wrappers.<ResumeTemplate>lambdaQuery()
                        .orderByAsc(ResumeTemplate::getSortOrder)
                        .orderByAsc(ResumeTemplate::getId)));
    }

    @PostMapping("/api/admin/resumes")
    public Result<Boolean> create(@Valid @RequestBody ResumeTemplate entity) {
        if (entity.getStatus() == null) {
            entity.setStatus(1);
        }
        return Result.ok(resumeTemplateService.create(entity));
    }

    @PutMapping("/api/admin/resumes")
    public Result<Boolean> update(@Valid @RequestBody ResumeTemplate entity) {
        return Result.ok(resumeTemplateService.modify(entity));
    }

    @DeleteMapping("/api/admin/resumes/{id}")
    public Result<Boolean> delete(@PathVariable Long id) {
        return Result.ok(resumeTemplateService.removeChecked(id));
    }
}
