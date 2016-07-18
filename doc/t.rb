# This is a temp file used for notes. Ignore it entirely!

foo = 0
willing_to_try = 5
begin
  puts "here."
  begin
    foo += 1
    puts "go # #{foo}"
    raise Timeout::Error.new("Haha! #{foo}") unless foo == 4
    willing_to_try = 0
  rescue Timeout::Error => e
    puts("Timeout")
    # wait_for_recovery(0)
    willing_to_try -= 1
    if willing_to_try > 0
      puts("Still willing to try #{willing_to_try} times")
    else
      puts("I GIVE UP!")
      raise e
    end
  end
  puts "I made it! (willing to try: #{willing_to_try})"
end while willing_to_try > 0
