local helper = require("kivi.lib.testlib.helper")
local kivi = helper.require("kivi")

describe("kivi file source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can execute child action", function()
    helper.new_file("file")

    helper.wait(kivi.open())
    vim.cmd("normal! G")
    helper.wait(kivi.execute("child"))

    assert.file_name("file")
  end)

  it("can execute parent action", function()
    helper.new_file("file")
    helper.new_directory("dir")
    helper.cd("dir")

    helper.wait(kivi.open())
    helper.wait(kivi.execute("parent"))

    assert.exists_pattern("file")
    assert.current_line("dir/")
  end)

  it("moves current directory", function()
    helper.new_directory("dir")

    helper.wait(kivi.open())
    helper.search("dir")
    helper.wait(kivi.execute("child"))

    assert.current_dir("dir")
    assert.exists_pattern("dir/")
  end)

  it("place cursor to the node that has source buffer's file path", function()
    helper.new_file("file1")
    helper.new_file("file2")
    helper.new_file("file3")

    vim.cmd("edit file3")

    helper.wait(kivi.open())

    assert.current_line("file3")
  end)

  it("raise error if path does not exist", function()
    helper.wait(kivi.open({ path = "invalid_file_path" }))
    assert.exists_message("does not exist: invalid_file_path")
  end)

  it("can delete file", function()
    helper.set_inputs("y")

    helper.new_file("file1")
    helper.new_file("file2")

    helper.wait(kivi.open())
    helper.search("file1")
    helper.wait(kivi.execute("delete"))

    assert.no.exists_pattern("file1")
    assert.exists_pattern("file2")
  end)

  it("can delete directory", function()
    helper.set_inputs("y")

    helper.new_directory("dir1")
    helper.new_file("dir1/file")
    helper.new_directory("dir2")

    helper.wait(kivi.open())
    helper.search("dir1")
    helper.wait(kivi.execute("delete"))

    assert.no.exists_pattern("dir1")
    assert.exists_pattern("dir2")
  end)

  it("can cancel deleting", function()
    helper.set_inputs("n")

    helper.new_file("file")

    helper.wait(kivi.open())
    helper.search("file")
    helper.wait(kivi.execute("delete"))

    assert.exists_pattern("file")
    assert.exists_message("canceled.")
  end)

  it("saves tree on deleting", function()
    helper.set_inputs("y")

    helper.new_file("file")
    helper.new_directory("dir")
    helper.new_file("dir/in_dir")

    helper.wait(kivi.open())

    helper.search("dir")
    helper.wait(kivi.execute("toggle_tree"))

    helper.search("file")
    helper.wait(kivi.execute("delete"))

    assert.no.exists_pattern("file")
    assert.exists_pattern("  in_dir")
  end)

  it("saves tree on pasting", function()
    helper.new_file("file")
    helper.new_directory("dir")
    helper.new_file("dir/in_dir")

    helper.wait(kivi.open())

    helper.search("dir")
    helper.wait(kivi.execute("toggle_tree"))

    helper.search("in_dir")
    helper.wait(kivi.execute("copy"))

    helper.search("file")
    helper.wait(kivi.execute("paste"))

    assert.exists_pattern("^in_dir$")
    assert.exists_pattern("  in_dir$")
  end)

  it("can execute vsplit_open action", function()
    helper.new_file("file1")

    helper.wait(kivi.open())
    helper.wait(kivi.execute("vsplit_open"))

    assert.window_count(2)
  end)

  it("can copy file and paste", function()
    helper.new_file("file")
    helper.new_directory("dir")

    helper.wait(kivi.open())

    helper.search("file")
    helper.wait(kivi.execute("copy"))
    assert.exists_message("copied: .*file")

    helper.search("dir")
    helper.wait(kivi.execute("child"))

    helper.wait(kivi.execute("paste"))

    assert.exists_pattern("file")

    helper.wait(kivi.execute("parent"))
    assert.exists_pattern("file")
  end)

  it("can copy directory and paste", function()
    helper.new_directory("dir1")
    helper.new_file("dir1/file")
    helper.new_directory("dir2")

    helper.wait(kivi.open())

    helper.search("dir1")
    helper.wait(kivi.execute("copy"))

    helper.search("dir2")
    helper.wait(kivi.execute("child"))

    helper.wait(kivi.execute("paste"))

    helper.search("dir1")
    helper.wait(kivi.execute("child"))

    assert.exists_pattern("file")

    helper.wait(kivi.execute("parent"))
    helper.wait(kivi.execute("parent"))
    assert.exists_pattern("dir1")
    assert.exists_pattern("dir2")
  end)

  it("can copy file and force paste", function()
    helper.new_file("file", [[test]])
    helper.new_directory("dir")
    helper.new_file("dir/file", [[overwrriten]])

    helper.wait(kivi.open())

    helper.search("file")
    helper.wait(kivi.execute("copy"))

    helper.search("dir")
    helper.wait(kivi.execute("child"))

    helper.set_inputs("f")
    helper.wait(kivi.execute("paste"))

    assert.exists_pattern("file")

    helper.search("file")
    helper.wait(kivi.execute("vsplit_open"))
    assert.current_line("test")
    vim.cmd("wincmd p")

    helper.wait(kivi.execute("parent"))
    assert.exists_pattern("file")
  end)

  it("can copy directory and force paste", function()
    helper.new_directory("dir1")
    helper.new_file("dir1/file", [[test]])

    helper.new_directory("dir2")
    helper.new_directory("dir2/dir1")
    helper.new_file("dir2/dir1/file")

    helper.wait(kivi.open())

    helper.search("dir1")
    helper.wait(kivi.execute("copy"))

    helper.search("dir2")
    helper.wait(kivi.execute("child"))

    helper.set_inputs("f")
    helper.wait(kivi.execute("paste"))

    helper.search("dir1")
    helper.wait(kivi.execute("child"))

    helper.search("file")
    helper.wait(kivi.execute("vsplit_open"))
    assert.current_line("test")
  end)

  it("can copy file and rename paste", function()
    helper.new_file("file", [[test]])
    helper.new_directory("dir")
    helper.new_file("dir/file", [[ok]])

    helper.wait(kivi.open())

    helper.search("file")
    helper.wait(kivi.execute("copy"))

    helper.search("dir")
    helper.wait(kivi.execute("child"))

    helper.set_inputs("r")
    helper.wait(kivi.execute("paste"))

    vim.cmd("s/file/renamed/")
    vim.cmd("write")
    helper.wait(kivi.promise())
    vim.cmd("wincmd p")

    assert.current_line("renamed")
    assert.exists_pattern("file")

    vim.cmd("wincmd w")
    vim.cmd("s/renamed/again/")
    vim.cmd("write")
    helper.wait(kivi.promise())
    vim.cmd("wincmd p")

    assert.no.exists_pattern("renamed")
    assert.exists_pattern("again")
  end)

  it("can copy directory and rename paste", function()
    helper.new_directory("dir1")
    helper.new_file("dir1/file", [[test]])

    helper.new_directory("dir2")
    helper.new_directory("dir2/dir1")

    helper.wait(kivi.open())

    helper.search("dir1")
    helper.wait(kivi.execute("copy"))

    helper.search("dir2")
    helper.wait(kivi.execute("child"))

    helper.set_inputs("r")
    helper.wait(kivi.execute("paste"))

    vim.cmd("s/dir1/renamed/")
    vim.cmd("write")
    helper.wait(kivi.promise())
    vim.cmd("wincmd p")

    assert.exists_pattern("dir1")

    helper.search("renamed")
    helper.wait(kivi.execute("child"))

    helper.search("file")
    helper.wait(kivi.execute("vsplit_open"))
    assert.current_line("test")
  end)

  it("can cut file and paste", function()
    helper.new_file("file")
    helper.new_directory("dir")

    helper.wait(kivi.open())

    helper.search("file")
    helper.wait(kivi.execute("cut"))
    assert.exists_message("cut: .*file")

    helper.search("dir")
    helper.wait(kivi.execute("child"))

    helper.wait(kivi.execute("paste"))

    assert.exists_pattern("file")

    helper.wait(kivi.execute("parent"))
    assert.no.exists_pattern("file")
  end)

  it("can cut directory and paste", function()
    helper.new_directory("dir1")
    helper.new_file("dir1/file")
    helper.new_directory("dir2")

    helper.wait(kivi.open())

    helper.search("dir1")
    helper.wait(kivi.execute("cut"))

    helper.search("dir2")
    helper.wait(kivi.execute("child"))

    helper.wait(kivi.execute("paste"))

    helper.search("dir1")
    helper.wait(kivi.execute("child"))

    assert.exists_pattern("file")

    helper.wait(kivi.execute("parent"))
    helper.wait(kivi.execute("parent"))
    assert.no.exists_pattern("dir1")
    assert.exists_pattern("dir2")
  end)

  it("can paste empty", function()
    helper.new_file("file")

    helper.wait(kivi.open())
    helper.wait(kivi.execute("paste"))

    assert.exists_pattern("file")
  end)

  it("can rename file", function()
    helper.new_file("file")

    helper.wait(kivi.open())
    helper.wait(kivi.execute("rename"))

    assert.current_line("file")

    vim.cmd("s/file/renamed/")
    vim.cmd("wq")
    helper.wait(kivi.promise())

    assert.no.exists_pattern("file")
    assert.exists_pattern("renamed")
  end)

  it("can rename directory", function()
    helper.new_directory("dir")

    helper.wait(kivi.open())
    helper.wait(kivi.execute("rename"))

    assert.current_line("dir/")

    vim.cmd("s/dir/renamed/")
    vim.cmd("wq")
    helper.wait(kivi.promise())

    assert.no.exists_pattern("dir")
    assert.exists_pattern("renamed/")
  end)

  it("can create file in root", function()
    helper.wait(kivi.open())

    helper.wait(kivi.execute("create"))

    vim.fn.setline(1, "created")
    vim.cmd("w")
    helper.wait(kivi.promise())

    assert.exists_pattern("created")
  end)

  it("can create file in expanded tree", function()
    helper.new_directory("dir")
    helper.new_file("dir/file1")

    helper.wait(kivi.open())

    helper.search("dir")
    helper.wait(kivi.execute("toggle_tree"))

    helper.search("file1")
    helper.wait(kivi.execute("create"))

    vim.fn.setline(1, "created")
    vim.cmd("w")
    helper.wait(kivi.promise())

    assert.exists_pattern("  created")
  end)

  it("can create directory", function()
    helper.wait(kivi.open())

    helper.wait(kivi.execute("create"))

    vim.fn.setline(1, "created/")
    vim.cmd("w")
    helper.wait(kivi.promise())

    assert.exists_pattern("created/")
  end)

  it("can create directory and file", function()
    helper.wait(kivi.open())

    helper.wait(kivi.execute("create"))

    vim.fn.setline(1, "created1/created2/file")
    vim.cmd("w")
    helper.wait(kivi.promise())

    assert.exists_pattern("created1/")
    assert.exists_pattern("  created2/")
    assert.exists_pattern("    file")
  end)

  it("can't create directory if it exists as file", function()
    helper.new_file("target")

    helper.wait(kivi.open())

    helper.wait(kivi.execute("create"))

    vim.fn.setline(1, "target/file")
    vim.cmd("w")

    assert.exists_message(("can't create: %starget/"):format(helper.test_data_dir))

    vim.cmd("wincmd p")
    assert.no.exists_pattern("target/")
  end)

  it("can open a file including percent", function()
    helper.new_file("file%", "content")

    helper.wait(kivi.open())
    helper.search("file")

    helper.wait(kivi.execute("child"))

    assert.exists_pattern("content")
  end)

  it("can open project root", function()
    helper.new_directory("root_marker")
    helper.new_directory("root_marker/dir1")
    helper.new_directory("root_marker/dir1/dir2")
    helper.cd("root_marker/dir1/dir2")

    helper.wait(kivi.open({ source_setup_opts = { target = "project", root_patterns = { "root_marker" } } }))

    assert.exists_pattern("root_marker/")
  end)

  it("can move from project root", function()
    helper.new_directory("root_marker")
    helper.new_directory("root_marker/dir")
    helper.cd("root_marker/dir")

    helper.wait(kivi.open({ source_setup_opts = { target = "project", root_patterns = { "root_marker" } } }))

    helper.search("root_marker/")
    helper.wait(kivi.execute("child"))

    assert.exists_pattern("dir/")
  end)

  it("can navigate to specific path", function()
    helper.new_directory("dir1/dir2")
    helper.new_file("dir1/dir2/file")

    helper.wait(kivi.open())
    helper.wait(kivi.navigate("./dir1/dir2/"))

    assert.exists_pattern("file")
  end)

  it("can deal with strange name", function()
    local dir = [[dir'"#%!'"]]
    helper.new_directory(dir)
    helper.new_file(dir .. "/file")

    helper.wait(kivi.open())
    helper.search("dir")
    helper.wait(kivi.execute("child"))

    assert.current_dir(dir)
  end)

  it("can expand parent", function()
    helper.new_directory("marker")
    helper.new_directory("dir1")
    helper.new_directory("dir1/dir2")
    helper.new_file("dir1/dir2/file")
    helper.cd("dir1/dir2")

    helper.wait(kivi.open())
    helper.wait(kivi.execute("expand_parent", {}, { root_patterns = { "marker" } }))

    assert.exists_pattern("^dir1/$")
    assert.exists_pattern("^  dir2/$")
    assert.exists_pattern("^    file$")
  end)

  it("saves history on expand_parent", function()
    helper.new_directory("a")
    helper.new_directory("b")
    helper.new_directory("c")
    helper.new_directory("dir1/marker")
    helper.new_directory("dir1/dir2/dir3")
    helper.cd("dir1/dir2/dir3")

    helper.wait(kivi.open())
    helper.wait(kivi.execute("expand_parent", {}, { root_patterns = { "marker" } }))
    helper.wait(kivi.execute("parent"))

    assert.current_line("dir1/")
  end)
end)
