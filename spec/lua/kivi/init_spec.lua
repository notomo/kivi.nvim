local helper = require("kivi.lib.testlib.helper")
local kivi = helper.require("kivi")

describe("kivi", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can open ui", function()
    helper.wait(kivi.open())

    assert.filetype("kivi-file")
  end)

  it("can reload ui", function()
    helper.test_data:create_file("file")

    helper.wait(kivi.open())
    vim.cmd.edit({ bang = true })
    helper.wait(kivi.promise())

    assert.exists_pattern("file")
  end)

  it("can remember path history", function()
    helper.test_data:create_dir("dir")
    helper.test_data:create_file("dir/file1")
    helper.test_data:create_file("dir/file2")
    helper.test_data:cd("dir")

    helper.wait(kivi.open())
    helper.search("file2")

    helper.wait(kivi.execute("parent"))

    helper.wait(kivi.execute("child"))

    assert.current_line("file2")
  end)

  it("opens with the cursor on the second line", function()
    helper.test_data:create_file("file1")
    helper.test_data:create_file("file2")

    helper.wait(kivi.open())

    assert.current_line("file1")
  end)

  it("can execute yank action", function()
    vim.g.clipboard = helper.clipboard()

    helper.test_data:create_file("file1")
    helper.test_data:create_file("file2")

    helper.wait(kivi.open())

    helper.search("file1")
    helper.wait(kivi.execute("toggle_selection"))
    helper.search("file2")
    helper.wait(kivi.execute("toggle_selection"))

    helper.wait(kivi.execute("yank"))

    assert.register_value("+", helper.test_data.full_path .. "file1\n" .. helper.test_data.full_path .. "file2")
    assert.exists_message("yank:$")
    assert.exists_message("file1$")
    assert.exists_message("file2$")
  end)

  it("can execute back action", function()
    helper.test_data:create_dir("dir1")
    helper.test_data:create_dir("dir1/dir2")

    helper.wait(kivi.open({ path = "dir1/dir2" }))
    helper.wait(kivi.execute("parent"))
    helper.wait(kivi.execute("parent"))
    helper.wait(kivi.execute("back"))

    assert.current_dir("dir1")

    helper.wait(kivi.execute("back"))
    assert.current_dir("dir1/dir2")

    helper.wait(kivi.execute("back"))
    assert.current_dir("dir1/dir2")
  end)

  it("can select nodes and execute action", function()
    helper.test_data:create_file("file1")
    helper.test_data:create_file("file2")
    helper.test_data:create_file("file3")

    helper.wait(kivi.open())
    helper.search("file2")
    helper.wait(kivi.execute("toggle_selection"))
    helper.search("file3")
    helper.wait(kivi.execute("toggle_selection"))
    helper.wait(kivi.execute("tab_open"))

    assert.tab_count(3)
  end)

  it("can reset selections by action", function()
    helper.test_data:create_file("file1")
    helper.test_data:create_file("file2")

    helper.wait(kivi.open())
    helper.search("file1")
    helper.wait(kivi.execute("toggle_selection"))
    helper.wait(kivi.execute("tab_open"))

    vim.cmd.tabprevious()
    helper.search("file2")
    helper.wait(kivi.execute("tab_open"))

    assert.tab_count(3)
  end)

  it("can reset selections by toggle_selection action", function()
    helper.test_data:create_file("file1")
    helper.test_data:create_file("file2")

    helper.wait(kivi.open())
    helper.search("file1")
    helper.wait(kivi.execute("toggle_selection"))
    helper.wait(kivi.execute("toggle_selection"))
    helper.search("file2")
    helper.wait(kivi.execute("tab_open"))

    assert.tab_count(2)
    assert.buffer_name_tail("file2")
  end)

  it("can toggle tree", function()
    helper.test_data:create_dir("dir")
    helper.test_data:create_file("dir/file")

    helper.wait(kivi.open())

    helper.search("dir")
    helper.wait(kivi.execute("toggle_tree"))

    assert.exists_pattern("  file")
    assert.current_line("dir/")

    helper.wait(kivi.execute("toggle_tree"))

    assert.current_line("dir/")
    assert.no.exists_pattern("  file")
  end)

  it("ignores layout on toggle tree", function()
    helper.test_data:create_dir("dir")

    helper.wait(kivi.open({ layout = { type = "vertical" } }))

    helper.search("dir")
    helper.wait(kivi.execute("toggle_tree"))

    assert.window_count(2)
  end)

  it("can open with hide layout", function()
    helper.test_data:create_file("file")
    local bufnr = vim.api.nvim_create_buf(false, true)

    helper.wait(kivi.open({ layout = { type = "hide" }, bufnr = bufnr }))

    assert.window_count(1)

    vim.cmd.buffer(bufnr)
    assert.exists_pattern("file")
  end)

  it("can reload renamer", function()
    helper.test_data:create_file("file")

    helper.wait(kivi.open())

    helper.search("file")
    helper.wait(kivi.execute("rename"))

    vim.cmd.edit({ bang = true })

    assert.exists_pattern("file")
  end)

  it("shows already exists error on creator", function()
    helper.test_data:create_file("file")

    helper.wait(kivi.open())
    helper.wait(kivi.execute("create"))

    vim.fn.setline(1, "file")
    vim.cmd.write()
    helper.wait(kivi.promise())

    assert.exists_message("already exists: .*/file")
  end)

  it("shows already exists error on renamer", function()
    helper.test_data:create_file("file1")
    helper.test_data:create_file("file2")

    helper.wait(kivi.open())

    helper.search("file1")
    helper.wait(kivi.execute("rename"))

    vim.cmd.substitute("/file1/file2/")
    vim.cmd.write()
    helper.wait(kivi.promise())

    assert.exists_message("already exists: .*/file2")
  end)

  it("shows `can't open` error", function()
    helper.skip_if_win32(pending)
    helper.wait(kivi.open({ path = "/root" }))
    assert.exists_message("can't open /root/")
  end)

  it("can execute action and close ui by quit option", function()
    helper.test_data:create_file("file1")
    helper.test_data:create_file("file2")
    vim.cmd.edit("file1")

    helper.wait(kivi.open({ layout = { type = "vertical" } }))

    helper.search("file2")
    helper.wait(kivi.execute("vsplit_open", { quit = true }))

    assert.window_count(2)
  end)

  it("can execute tab_open node", function()
    helper.test_data:create_file("file1")
    helper.test_data:create_dir("dir")
    helper.test_data:create_file("dir/file2")

    helper.wait(kivi.open())

    helper.search("dir")
    helper.wait(kivi.execute("tab_open"))

    assert.tab_count(2)
    assert.exists_pattern("file2")

    vim.cmd.tabprevious()
    assert.exists_pattern("file1")
  end)

  it("can return whether the node is parent", function()
    helper.wait(kivi.open())

    assert.is_same(true, kivi.is_parent())
  end)

  it("can return whether the node is not parent", function()
    helper.test_data:create_file("file")

    helper.wait(kivi.open())
    helper.search("file")

    assert.is_same(false, kivi.is_parent())
  end)

  it("does not recall expanded tree", function()
    helper.test_data:create_dir("dir")
    helper.test_data:create_file("dir/file")

    helper.wait(kivi.open({ layout = { type = "tab" } }))
    helper.search("dir")
    helper.wait(kivi.execute("toggle_tree"))
    vim.cmd.quit()
    helper.wait(kivi.open({ layout = { type = "tab" } }))

    assert.no.exists_pattern("file")
  end)

  it("ignores duplicated path history", function()
    helper.test_data:create_dir("dir1/dir2")

    helper.wait(kivi.open())
    helper.wait(kivi.navigate(helper.test_data.full_path .. "dir1"))
    helper.wait(kivi.navigate(helper.test_data.full_path .. "dir1/dir2"))
    helper.wait(kivi.navigate(helper.test_data.full_path .. "dir1/dir2"))
    helper.wait(kivi.navigate(helper.test_data.full_path .. "dir1/dir2"))
    helper.wait(kivi.execute("back"))

    assert.current_dir("dir1")
  end)

  it("can close all tree", function()
    helper.test_data:create_dir("dir1")
    helper.test_data:create_file("dir1/file1")
    helper.test_data:create_dir("dir2")
    helper.test_data:create_file("dir2/file2")
    helper.test_data:create_file("dir2/file3")

    helper.wait(kivi.open())

    helper.search("dir1")
    helper.wait(kivi.execute("toggle_tree"))

    helper.search("dir2")
    helper.wait(kivi.execute("toggle_tree"))
    helper.search("file2")

    helper.wait(kivi.execute("close_all_tree"))

    assert.current_line("file2")
  end)

  it("can shrink tree", function()
    helper.test_data:create_dir("dir")
    helper.test_data:create_file("dir/file1")
    helper.test_data:create_file("dir/file2")

    helper.wait(kivi.open())
    helper.search("dir")
    helper.wait(kivi.execute("toggle_tree"))
    helper.search("file2")

    helper.wait(kivi.execute("shrink"))

    assert.no.exists_pattern("^  file")
    assert.current_line("file2")
  end)

  it("can debug_print node", function()
    helper.test_data:create_dir("dir")

    helper.wait(kivi.open())
    helper.search("dir")
    helper.wait(kivi.execute("debug_print"))

    assert.exists_message([[value = "dir/"]])
  end)
end)
