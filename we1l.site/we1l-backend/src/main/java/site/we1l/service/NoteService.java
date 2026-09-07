package site.we1l.service;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.springframework.stereotype.Service;
import site.we1l.entity.Note;
import site.we1l.mapper.NoteMapper;

import java.util.List;

/**
 * 学习笔记服务。
 */
@Service
public class NoteService extends BaseService<NoteMapper, Note> {

    /** 前台列表：仅启用，按发布时间倒序 */
    public List<Note> listEnabled() {
        return lambdaQuery()
                .eq(Note::getStatus, 1)
                .orderByDesc(Note::getPublishedAt)
                .orderByDesc(Note::getId)
                .list();
    }

    /** 后台分页：支持按分类与标题关键词过滤 */
    public Page<Note> search(Page<Note> page, String category, String keyword) {
        return page(page, Wrappers.<Note>lambdaQuery()
                .eq(category != null && !category.isBlank(), Note::getCategory, category)
                .and(keyword != null && !keyword.isBlank(),
                        w -> w.like(Note::getTitle, keyword).or().like(Note::getSummary, keyword))
                .orderByDesc(Note::getPublishedAt)
                .orderByDesc(Note::getId));
    }

    /** 阅读量自增 */
    public void incrViews(Long id) {
        Note note = getById(id);
        if (note != null) {
            note.setViews((note.getViews() == null ? 0 : note.getViews()) + 1);
            updateById(note);
        }
    }
}
