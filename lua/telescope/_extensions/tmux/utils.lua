local utils = {}

utils.apply_default_layout = function(opts)
    return vim.tbl_extend("keep", opts, {layout_strategy='horizontal', layout_config={preview_width=0.8}})
end

return utils
