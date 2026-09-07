package site.we1l.controller;

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
import site.we1l.common.BusinessException;
import site.we1l.common.Result;
import site.we1l.entity.Skill;
import site.we1l.service.SkillService;

import java.util.List;

/**
 * 「关于我」— 技能（进度条 BAR / 雷达图 RADAR）。
 * 前台：GET /api/skills?type=BAR
 * 后台：/api/admin/skills/**
 */
@RestController
@RequestMapping
@RequiredArgsConstructor
public class SkillController {

    private static final String TYPE_BAR = "BAR";
    private static final String TYPE_RADAR = "RADAR";

    private final SkillService skillService;

    @GetMapping("/api/skills")
    public Result<List<Skill>> list(@RequestParam(defaultValue = TYPE_BAR) String type) {
        String normalized = type == null ? TYPE_BAR : type.trim().toUpperCase();
        if (!TYPE_BAR.equals(normalized) && !TYPE_RADAR.equals(normalized)) {
            throw new BusinessException("技能类型只能是 BAR 或 RADAR");
        }
        return Result.ok(skillService.listByType(normalized));
    }

    @GetMapping("/api/admin/skills/page")
    public Result<Page<Skill>> page(@RequestParam(defaultValue = "1") long current,
                                    @RequestParam(defaultValue = "10") long size,
                                    @RequestParam(required = false) String type) {
        return Result.ok(skillService.pageByType(new Page<>(current, size), type));
    }

    @PostMapping("/api/admin/skills")
    public Result<Boolean> create(@Valid @RequestBody Skill entity) {
        normalize(entity);
        return Result.ok(skillService.create(entity));
    }

    @PutMapping("/api/admin/skills")
    public Result<Boolean> update(@Valid @RequestBody Skill entity) {
        normalize(entity);
        return Result.ok(skillService.modify(entity));
    }

    @DeleteMapping("/api/admin/skills/{id}")
    public Result<Boolean> delete(@PathVariable Long id) {
        return Result.ok(skillService.removeChecked(id));
    }

    private void normalize(Skill entity) {
        if (entity.getSkillType() != null) {
            entity.setSkillType(entity.getSkillType().trim().toUpperCase());
        }
        if (entity.getStatus() == null) {
            entity.setStatus(1);
        }
    }
}
