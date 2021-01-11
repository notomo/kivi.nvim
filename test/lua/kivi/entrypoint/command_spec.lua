local helper = require("kivi/lib/testlib/helper")
local command = helper.command

describe("kivi", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can open ui", function()
    command("Kivi")

    assert.filetype("kivi-file")
  end)

  it("can reload ui", function()
    helper.new_file("file")

    command("Kivi")
    command("edit!")

    assert.exists_pattern("file")
  end)

  it("can remember path history", function()
    helper.new_directory("dir")
    helper.new_file("dir/file1")
    helper.new_file("dir/file2")
    helper.cd("dir")

    command("Kivi")
    helper.search("file2")

    command("KiviDo parent")

    command("KiviDo child")

    assert.current_line("file2")
  end)

  it("opens with the cursor on the second line", function()
    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")

    assert.current_line("file1")
  end)

  it("can execute yank action", function()
    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")

    helper.search("file1")
    command("KiviDo toggle_selection")
    helper.search("file2")
    command("KiviDo toggle_selection")

    command("KiviDo yank")

    assert.register_value("+", helper.test_data_dir .. "file1\n" .. helper.test_data_dir .. "file2")
    assert.exists_message("yank:$")
    assert.exists_message("file1$")
    assert.exists_message("file2$")
  end)

  it("can execute back action", function()
    helper.new_directory("dir1")
    helper.new_directory("dir1/dir2")

    command("Kivi --path=dir1/dir2")
    command("KiviDo parent")
    command("KiviDo parent")
    command("KiviDo back")

    assert.current_dir("dir1")

    command("KiviDo back")
    assert.current_dir("dir1/dir2")

    command("KiviDo back")
    assert.current_dir("dir1/dir2")
  end)

  it("can select nodes and execute action", function()
    helper.new_file("file1")
    helper.new_file("file2")
    helper.new_file("file3")

    command("Kivi")
    helper.search("file2")
    command("KiviDo toggle_selection")
    helper.search("file3")
    command("KiviDo toggle_selection")
    command("KiviDo tab_open")

    assert.tab_count(3)
  end)

  it("can reset selections by action", function()
    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")
    helper.search("file1")
    command("KiviDo toggle_selection")
    command("KiviDo tab_open")

    command("tabprevious")
    helper.search("file2")
    command("KiviDo tab_open")

    assert.tab_count(3)
  end)

  it("can reset selections by toggle_selection action", function()
    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")
    helper.search("file1")
    command("KiviDo toggle_selection")
    command("KiviDo toggle_selection")
    helper.search("file2")
    command("KiviDo tab_open")

    assert.tab_count(2)
    assert.file_name("file2")
  end)

  it("does not move the cursor on opening the same path", function()
    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")
    helper.search("file2")
    command("Kivi")

    assert.current_line("file2")
  end)

  it("can toggle tree", function()
    helper.new_directory("dir")
    helper.new_file("dir/file")

    command("Kivi")

    helper.search("dir")
    command("KiviDo toggle_tree")

    assert.exists_pattern("  file")
    assert.current_line("dir/")

    command("KiviDo toggle_tree")

    assert.current_line("dir/")
    assert.no.exists_pattern("  file")
  end)

  it("ignores layout on toggle tree", function()
    helper.new_directory("dir")

    command("Kivi --layout=vertical")

    helper.search("dir")
    command("KiviDo toggle_tree")

    assert.window_count(2)
  end)

  it("can reload renamer", function()
    helper.new_file("file")

    command("Kivi")

    helper.search("file")
    command("KiviDo rename")

    command("edit!")

    assert.exists_pattern("file")
  end)

  it("shows already exists error on creator", function()
    helper.new_file("file")

    command("Kivi")
    command("KiviDo create")

    vim.fn.setline(1, "file")
    command("w")

    assert.exists_message("already exists: .*/file")
  end)

  it("shows already exists error on renamer", function()
    helper.new_file("file1")
    helper.new_file("file2")

    command("Kivi")

    helper.search("file1")
    command("KiviDo rename")

    command("s/file1/file2/")
    command("w")

    assert.exists_message("already exists: .*/file2")
  end)

  it("shows `can't open` error", function()
    helper.skip_if_win32(pending)
    assert.error_message("can't open /root/", function()
      command("Kivi --path=/root")
    end)
  end)

  it("can execute action and close ui by quit option", function()
    helper.new_file("file1")
    helper.new_file("file2")
    command("edit file1")

    command("Kivi --layout=vertical")

    helper.search("file2")
    command("KiviDo vsplit_open --quit")

    assert.window_count(2)
  end)

  it("can execute tab_open node", function()
    helper.new_file("file1")
    helper.new_directory("dir")
    helper.new_file("dir/file2")

    command("Kivi")

    helper.search("dir")
    command("KiviDo tab_open")

    assert.tab_count(2)
    assert.exists_pattern("file2")

    command("tabprevious")
    assert.exists_pattern("file1")
  end)

  it("can open project root", function()
    require("kivi/core/target").project_root_patterns = {"root_marker"}

    helper.new_directory("root_marker")
    helper.new_directory("root_marker/dir1")
    helper.new_directory("root_marker/dir1/dir2")
    helper.cd("root_marker/dir1/dir2")

    command("Kivi --target=project")

    assert.exists_pattern("root_marker/")
  end)

end)
