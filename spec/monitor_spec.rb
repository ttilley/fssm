require "spec_helper"

require "fileutils"
require "tempfile"

module FSSM::MonitorSpecHelpers
  def create_tmp_dir
    @tmp_dir = Dir.mktmpdir
    FileUtils.cp_r File.join(File.dirname(__FILE__), 'root'), @tmp_dir
    # Because git does not track empty directories, create one ourselves.
    FileUtils.mkdir_p @tmp_dir + '/root/yawn'
    @tmp_dir
  end

  def remove_tmp_dir
    FileUtils.remove_entry_secure @tmp_dir
  end

  def create_handler(type)
    lambda {|base, relative| @handler_results[type] << [base, relative]}
  end

  def create_monitor(options={})
    @handler_results = Hash.new {|hash, key| hash[key] = []}
    @monitor = FSSM::Monitor.new(options)
    @monitor.path(@tmp_dir) do |p|
      p.create(&create_handler(:create))
      p.update(&create_handler(:update))
      p.delete(&create_handler(:delete))
    end
    sleep 1     # give time for monitor to preload
  end

  def run_monitor
    thread = Thread.new {@monitor.run}
    sleep 2     # give time for monitor to see changes
    thread.kill
  end
end

describe "The File System State Monitor" do
  describe "monitor" do
    include FSSM::MonitorSpecHelpers

    before do
      create_tmp_dir
    end

    after do
      remove_tmp_dir
    end

    describe "with default options" do
      before do
        create_monitor
      end

      it "should call create callback upon file creation" do
        file = @tmp_dir + "/newfile.rb"
        File.exists?(file).should be_false
        FileUtils.touch file
        run_monitor
        @handler_results[:create].should == [[@tmp_dir, 'newfile.rb']]
      end

      it "should call update callback upon file modification" do
        FileUtils.touch @tmp_dir + '/root/file.rb'
        run_monitor
        @handler_results[:update].should == [[@tmp_dir, 'root/file.rb']]
      end

      it "should call delete callback upon file deletion" do
        FileUtils.rm @tmp_dir + "/root/file.rb"
        run_monitor
        @handler_results[:delete].should == [[@tmp_dir, 'root/file.rb']]
      end

      it "should call create and delete callbacks upon file renaming in the same directory" do
        FileUtils.mv @tmp_dir + "/root/file.rb", @tmp_dir + "/root/old_file.rb"
        run_monitor
        @handler_results[:create].should == [[@tmp_dir, 'root/old_file.rb']]
        @handler_results[:delete].should == [[@tmp_dir, 'root/file.rb']]
        @handler_results[:update].should == []
      end

      it "should call create and delete callbacks upon file moving to another directory" do
        FileUtils.mv @tmp_dir + "/root/file.rb", @tmp_dir + "/old_file.rb"
        run_monitor
        @handler_results[:create].should == [[@tmp_dir, 'old_file.rb']]
        @handler_results[:delete].should == [[@tmp_dir, 'root/file.rb']]
        @handler_results[:update].should == []
      end

      it "should not call callbacks upon directory operations" do
        FileUtils.mkdir @tmp_dir + "/another_yawn"
        FileUtils.rmdir @tmp_dir + "/root/yawn"
        run_monitor
        @handler_results[:create].should == []
        @handler_results[:delete].should == []
      end
    end

    describe "when configured to consider files and directories" do
      before do
        create_monitor(:directories => true)
      end

      it "should call create callback upon directory creation" do
        FileUtils.mkdir @tmp_dir + "/another_yawn"
        run_monitor
        @handler_results[:create].should == [[@tmp_dir, 'another_yawn']]
      end

      it "should call delete callback upon directory deletion" do
        FileUtils.rmdir @tmp_dir + "/root/yawn"
        run_monitor
        @handler_results[:delete].should == [[@tmp_dir, 'root/yawn']]
      end

      it "should call create, update, and delete callbacks upon directory renaming in the same directory" do
        FileUtils.mv @tmp_dir + "/root/yawn", @tmp_dir + "/root/old_yawn"
        run_monitor
        @handler_results[:create].should == [[@tmp_dir, 'root/old_yawn']]
        @handler_results[:delete].should == [[@tmp_dir, 'root/yawn']]
        @handler_results[:update].should == [[@tmp_dir, 'root']]
      end

      it "should call create, update, and delete callbacks upon directory moving to another directory" do
        FileUtils.mv @tmp_dir + "/root/yawn", @tmp_dir + "/old_yawn"
        run_monitor
        @handler_results[:create].should == [[@tmp_dir, 'old_yawn']]
        @handler_results[:delete].should == [[@tmp_dir, 'root/yawn']]
        @handler_results[:update].should == [[@tmp_dir, 'root']]
      end

      it "should call create, update, and delete callbacks upon file renaming in the same directory" do
        FileUtils.mv @tmp_dir + "/root/file.rb", @tmp_dir + "/root/old_file.rb"
        run_monitor
        @handler_results[:create].should == [[@tmp_dir, 'root/old_file.rb']]
        @handler_results[:delete].should == [[@tmp_dir, 'root/file.rb']]
        @handler_results[:update].should == [[@tmp_dir, 'root']]
      end

      it "should call create, update, and delete callbacks upon file moving to another directory" do
        FileUtils.mv @tmp_dir + "/root/file.rb", @tmp_dir + "/old_file.rb"
        run_monitor
        @handler_results[:create].should == [[@tmp_dir, 'old_file.rb']]
        @handler_results[:delete].should == [[@tmp_dir, 'root/file.rb']]
        @handler_results[:update].should == [[@tmp_dir, 'root']]
      end

      it "should call delete callbacks upon directory structure deletion, in reverse order" do
        FileUtils.rm_rf @tmp_dir + '/.'
        run_monitor
        @handler_results[:create].should == []
        @handler_results[:delete].should == %w{
            root/yawn
            root/moo/cow.txt
            root/moo
            root/file.yml
            root/file.rb
            root/file.css
            root/duck/quack.txt
            root/duck
            root
          }.map {|rel| [@tmp_dir, rel]}
        @handler_results[:update].should == []
      end

      it "should call create callbacks upon directory structure creation, in order" do
        FileUtils.cp_r @tmp_dir + '/root/.', @tmp_dir + '/new_root'
        run_monitor
        @handler_results[:create].should == %w{
            new_root
            new_root/duck
            new_root/duck/quack.txt
            new_root/file.css
            new_root/file.rb
            new_root/file.yml
            new_root/moo
            new_root/moo/cow.txt
            new_root/yawn
          }.map {|rel| [@tmp_dir, rel]}
        @handler_results[:delete].should == []
        @handler_results[:update].should == []
      end
    end
  end
end
