require 'optiflag'

# Title:  Character flags and clustering.
# Description: character flags are simple single character flags with zero arity and which are optional.  An optional symbol as a second parameter to the 'character_flag' groups the character within a cluster in the same name. This last point will probably change (see 'discussion' on the web page for a better idea).   
module HashAcess extend OptiFlagSet

  character_flag :l, :list_group
  character_flag :s, :list_group
  character_flag :a, :list_group

  character_flag :x do
    description "Extract"
  end
  character_flag :v do
    description "Verbose"
  end
  character_flag :f do
    description "Archive File"
  end

  and_process!
end 

f = ARGV.flags
puts "'l' flag set?: #{ f.l? }"
puts "'s' flag set?: #{ f.s? }"
puts "'a' flag set?: #{ f.a? }"
puts "'x' flag set?: #{ f.x? }"
puts "'f' flag set?: #{ f.f? }"
puts "'v' flag set?: #{ f.v? }"

#h# ruby example_7.rb -lsa
#h# ruby example_7.rb -ls -a
#h# ruby example_7.rb -a -s -l
#h# ruby example_7.rb -als -x -vf
#h# ruby example_7.rb -s -xvf
#h# ruby example_7.rb -lsaxvf



