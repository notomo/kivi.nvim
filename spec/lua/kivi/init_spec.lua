local helper = require("kivi.lib.testlib.helper")
local kivi = helper.require("kivi")

describe("kivi", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can open ui", function()
    kivi.open()

    assert.filetype("kivi-file")
  end)

  it("can reload ui", function()
    helper.new_file("file")

    kivi.open()
    vim.cmd("edit!")

    assert.exists_pattern("file")
  end)

  it("can remember path history", function()
    helper.new_directory("dir")
    helper.new_file("dir/file1")
    helper.new_file("dir/file2")
    helper.cd("dir")

    kivi.open()
    helper.search("file2")

    kivi.execute("parent")

    kivi.execute("child")

    assert.current_line("file2")
  end)

  it("opens with the cursor on the second line", function()
    helper.new_file("file1")
    helper.new_file("file2")

    kivi.open()

    assert.current_line("file1")
  end)

  it("can execute yank action", function()
    helper.new_file("file1")
    helper.new_file("file2")

    kivi.open()

    helper.search("file1")
    kivi.execute("toggle_selection")
    helper.search("file2")
    kivi.execute("toggle_selection")

    kivi.execute("yank")

    assert.register_value("+", helper.test_data_dir .. "file1\n" .. helper.test_data_dir .. "file2")
    assert.exists_message("yank:$")
    assert.exists_message("file1$")
    assert.exists_message("file2$")
  end)

  it("can execute back action", function()
    helper.new_directory("dir1")
    helper.new_directory("dir1/dir2")

    kivi.open({path = "dir1/dir2"})
    kivi.execute("parent")
    kivi.execute("parent")
    kivi.execute("back")

    assert.current_dir("dir1")

    kivi.execute("back")
    assert.current_dir("dir1/dir2")

    kivi.execute("back")
    assert.current_dir("dir1/dir2")
  end)

  it("can select nodes and execute action", function()
    helper.new_file("file1")
    helper.new_file("file2")
    helper.new_file("file3")

    kivi.open()
    helper.search("file2")
    kivi.execute("toggle_selection")
    helper.search("file3")
    kivi.execute("toggle_selection")
    kivi.execute("tab_open")

    assert.tab_count(3)
  end)

  it("can reset selections by action", function()
    helper.new_file("file1")
    helper.new_file("file2")

    kivi.open()
    helper.search("file1")
    kivi.execute("toggle_selection")
    kivi.execute("tab_open")

    vim.cmd("tabprevious")
    helper.search("file2")
    kivi.execute("tab_open")

    assert.tab_count(3)
  end)

  it("can reset selections by toggle_selection action", function()
    helper.new_file("file1")
    helper.new_file("file2")

    kivi.open()
    helper.search("file1")
    kivi.execute("toggle_selection")
    kivi.execute("toggle_selection")
    helper.search("file2")
    kivi.execute("tab_open")

    assert.tab_count(2)
    assert.file_name("file2")
  end)

  it("can toggle tree", function()
    helper.new_directory("dir")
    helper.new_file("dir/file")

    kivi.open()

    helper.search("dir")
    kivi.execute("toggle_tree")

    assert.exists_pattern("  file")
    assert.current_line("dir/")

    kivi.execute("toggle_tree")

    assert.current_line("dir/")
    assert.no.exists_pattern("  file")
  end)

  it("ignores layout on toggle tree", function()
    helper.new_directory("dir")

    kivi.open({layout = {type = "vertical"}})

    helper.search("dir")
    kivi.execute("toggle_tree")

    assert.window_count(2)
  end)

  it("can reload renamer", function()
    helper.new_file("file")

    kivi.open()

    helper.search("file")
    kivi.execute("rename")

    vim.cmd("edit!")

    assert.exists_pattern("file")
  end)

  it("shows already exists error on creator", function()
    helper.new_file("file")

    kivi.open()
    kivi.execute("create")

    vim.fn.setline(1, "file")
    vim.cmd("w")

    assert.exists_message("already exists: .*/file")
  end)

  it("shows already exists error on renamer", function()
    helper.new_file("file1")
    helper.new_file("file2")

    kivi.open()

    helper.search("file1")
    kivi.execute("rename")

    vim.cmd("s/file1/file2/")
    vim.cmd("w")

    assert.exists_message("already exists: .*/file2")
  end)

  it("shows `can't open` error", function()
    helper.skip_if_win32(pending)
    kivi.open({path = "/root"})
    assert.exists_message("can't open /root/")
  end)

  it("can execute action and close ui by quit option", function()
    helper.new_file("file1")
    helper.new_file("file2")
    vim.cmd("edit file1")

    kivi.open({layout = {type = "vertical"}})

    helper.search("file2")
    kivi.execute("vsplit_open", {quit = true})

    assert.window_count(2)
  end)

  it("can execute tab_open node", function()
    helper.new_file("file1")
    helper.new_directory("dir")
    helper.new_file("dir/file2")

    kivi.open()

    helper.search("dir")
    kivi.execute("tab_open")

    assert.tab_count(2)
    assert.exists_pattern("file2")

    vim.cmd("tabprevious")
    assert.exists_pattern("file1")
  end)

  it("can return whether the node is parent", function()
    kivi.open()

    assert.is_same(true, kivi.is_parent())
  end)

  it("can return whether the node is not parent", function()
    helper.new_file("file")

    kivi.open()
    helper.search("file")

    assert.is_same(false, kivi.is_parent())
  end)

  it("can config options", function()
    kivi.setup({opts = {layout = {type = "vertical"}}})

    kivi.open()

    assert.window_count(2)
  end)

  it("does not recall expanded tree", function()
    helper.new_directory("dir")
    helper.new_file("dir/file")

    kivi.open({layout = {type = "tab"}})
    helper.search("dir")
    kivi.execute("toggle_tree")
    vim.cmd("quit")
    kivi.open({layout = {type = "tab"}})

    assert.no.exists_pattern("file")
  end)

  it("ignores duplicated path history", function()
    helper.new_directory("dir1/dir2")

    kivi.open()
    kivi.navigate(helper.test_data_dir .. "dir1")
    kivi.navigate(helper.test_data_dir .. "dir1/dir2")
    kivi.navigate(helper.test_data_dir .. "dir1/dir2")
    kivi.navigate(helper.test_data_dir .. "dir1/dir2")
    kivi.execute("back")

    assert.current_dir("dir1")
  end)

end)
