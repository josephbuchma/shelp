#!/usr/bin/ruby

require 'thor'

module Helpers
  class Git < Thor
    desc 'filterdiff <against_commit> <regex>', '(alias fdiff) List files where regex matches any line of diff'
    option :edit, :desc=>'open matched files in $EDITOR'
    def filterdiff(commit, filter)
      pattern = Regexp.new(filter)
      all_files = `git diff --name-only #{commit}`
      matched_files = []
      all_files.strip.split(/\s+/).each do |f|
        s = `git diff #{commit} #{f}`
        if !s.valid_encoding?
          s = s.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
        end
        s.each_line do |line|
          if pattern =~ line then
            matched_files << f
            break
          end
        end
      end
      if options[:edit] then
        Kernel.exec("#{ENV['EDITOR']} #{matched_files.join(" ")}")
      else
        puts matched_files.join("\n")
      end
    end

    desc 'commitbranch <commit_msg_and_branch_name> [branch_name]', '(alias cb) Commit current changes to new branch and go back'
    def commitbranch(name, branch_name=nil)
      if branch_name.nil? then
        branch_name = name
      end
      current_branch = `git rev-parse --abbrev-ref HEAD`
      Kernel.system("git checkout -b #{branch_name}")
      Kernel.system("git add .")
      Kernel.system("git commit -m #{name}")
      Kernel.system("git checkout #{current_branch}")
    end

    map :fdiff => :filterdiff
    map :cb => :commitbranch
  end

  class Os < Thor
    desc 'sleepin <n minutes> [--background]', 'systemctl suspend in n minutes'
    option :background, :desc => 'wait in background process'
    def sleepin(mintues)
      if options[:background]
        exit if Kernel.fork
      end
      sleep(mintues.to_i * 60)
      Kernel.exec('systemctl suspend')
    end
  end

  class Helpers < Thor
    desc 'git SUBCOMMAND ...ARGS', 'git helpers'
    subcommand 'git', Git

    desc 'os SUBCOMMAND ...ARGS', 'OS helpers'
    subcommand 'os', Os
  end

end

Helpers::Helpers.start(ARGV)
