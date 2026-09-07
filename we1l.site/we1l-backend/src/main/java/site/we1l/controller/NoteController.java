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
import site.we1l.entity.Note;
import site.we1l.service.NoteService;

import java.util.List;

/**
 * 「笔记 / 服务」— 学习笔记。
 * 前台：GET /api/notes、GET /api/notes/{id}
 * 后台：/api/admin/notes/**
 */
@RestController
@RequestMapping
@RequiredArgsConstructor
public class NoteController {

    private final NoteService noteService;

    @GetMapping("/api/notes")
    public Result<List<Note>> list(@RequestParam(required = false) String category) {
        if (category != null && !category.isBlank()) {
            return Result.ok(noteService.lambdaQuery()
                    .eq(Note::getCategory, category)
                    .eq(Note::getStatus, 1)
                    .orderByDesc(Note::getPublishedAt)
                    .list());
        }
        return Result.ok(noteService.listEnabled());
    }

    @GetMapping("/api/notes/{id}")
    public Result<Note> detail(@PathVariable Long id) {
        Note note = noteService.getById(id);
        if (note == null) {
            throw new BusinessException(404, "笔记不存在");
        }
        noteService.incrViews(id);
        return Result.ok(note);
    }

    @GetMapping("/api/admin/notes/page")
    public Result<Page<Note>> page(@RequestParam(defaultValue = "1") long current,
                                   @RequestParam(defaultValue = "10") long size,
                                   @RequestParam(required = false) String category,
                                   @RequestParam(required = false) String keyword) {
        return Result.ok(noteService.search(new Page<>(current, size), category, keyword));
    }

    @PostMapping("/api/admin/notes")
    public Result<Boolean> create(@Valid @RequestBody Note entity) {
        if (entity.getStatus() == null) {
            entity.setStatus(1);
        }
        if (entity.getViews() == null) {
            entity.setViews(0);
        }
        return Result.ok(noteService.create(entity));
    }

    @PutMapping("/api/admin/notes")
    public Result<Boolean> update(@Valid @RequestBody Note entity) {
        return Result.ok(noteService.modify(entity));
    }

    @DeleteMapping("/api/admin/notes/{id}")
    public Result<Boolean> delete(@PathVariable Long id) {
        return Result.ok(noteService.removeChecked(id));
    }
}
