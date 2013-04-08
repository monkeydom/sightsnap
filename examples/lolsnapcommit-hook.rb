#!/usr/bin/env ruby

# to install simply copy to .git/hooks/post-commit in your repository

# single character escaping
class String
    def escape_single
        self.gsub("'","'\\\\''")
    end
end

commit = %x[git rev-parse --verify HEAD].strip
short_commit = commit[0..12]
top_level_dir = %x[git rev-parse --show-toplevel].strip
repo_name = File.basename(top_level_dir)
revision_number = %x[git rev-list HEAD | wc -l;].strip
commit_message = %x[git log -n 1 HEAD --format=format:%s%n%b].strip
branch_name = %x[git rev-parse --abbrev-ref HEAD].strip

# settings
title = "%s %s:%10s" % [repo_name, branch_name, short_commit]
font = "Futura-CondensedMedium"
font_size = 40

#print title, "\n"
#print commit_message, "\n"

snap_path = File.expand_path "~/Library/Application Support/lolsnap/#{repo_name}/#{repo_name}_#{short_commit}.jpg"

%x[/usr/bin/env sightsnap -p -T '#{title.escape_single}' -C '#{commit_message.escape_single}' -j 0.6 -f '#{font}' -s '#{font_size}' '#{snap_path.escape_single}' && open '#{snap_path.escape_single}']