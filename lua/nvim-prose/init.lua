local M = {}

local config = {
    wpm = 200.0,
    filetypes = { 'markdown', 'asciidoc' },
    placeholders = {
        words = '字',  -- 中文习惯
        minutes = '分钟'
    }
}

function M.setup(opts)
    opts = opts or {}
    if opts.wpm ~= nil then config.wpm = opts.wpm end
    if opts.filetypes ~= nil then config.filetypes = opts.filetypes end
    if opts.placeholders ~= nil then config.placeholders = opts.placeholders end
end

-- 精确统计中文字符（排除标点符号）
function M.word_count()
    local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, true), " ")
    local chinese_chars = 0
    
    -- 匹配 CJK 统一汉字（U+4E00-U+9FFF），排除标点
    for c in content:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if #c == 3 then
            local b1, b2 = c:byte(1), c:byte(2)
            -- 检查是否在 U+4E00-U+9FFF 范围内
            if b1 >= 0xE4 and b1 <= 0xE9 then
                if not (b1 == 0xE4 and b2 < 0xB8) then  -- 排除 U+4E00 以下的字符
                    chinese_chars = chinese_chars + 1
                end
            end
        end
    end
    
    local english_words = vim.fn.wordcount().words
    local total = chinese_chars + english_words
    
    if config.placeholders and config.placeholders.words then
        return tostring(total) .. ' ' .. config.placeholders.words
    end
    return tostring(total)
end

-- 保留阅读时间计算
function M.reading_time()
    local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, true), " ")
    local chinese_chars = 0
    
    -- 使用和 word_count() 相同的统计逻辑
    for c in content:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if #c == 3 then
            local b1, b2 = c:byte(1), c:byte(2)
            if b1 >= 0xE4 and b1 <= 0xE9 then
                if not (b1 == 0xE4 and b2 < 0xB8) then
                    chinese_chars = chinese_chars + 1
                end
            end
        end
    end
    
    local english_words = vim.fn.wordcount().words
    local total = chinese_chars + english_words
    local rt = math.ceil(total / config.wpm)
    
    if config.placeholders and config.placeholders.minutes then
        return tostring(rt) .. ' ' .. config.placeholders.minutes
    end
    return tostring(rt)
end

function M.is_available()
    if config.filetypes == nil then return false end
    for _, val in ipairs(config.filetypes) do
        if val == vim.bo.filetype then return true end
    end
    return false
end

return M