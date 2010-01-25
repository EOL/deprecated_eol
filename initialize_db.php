<?php 

echo "rake db:drop:all \n";                         shell_exec("rake db:drop:all");                         echo "Ended ----------- \n\n";
echo "rake eol:db:create:all \n";                   shell_exec("rake eol:db:create:all");                   echo "Ended ----------- \n\n";
echo "rake eol:db:create:all RAILS_ENV=test \n";    shell_exec("rake eol:db:create:all RAILS_ENV=test");    echo "Ended ----------- \n\n";
echo "rake db:migrate \n";                          shell_exec("rake db:migrate");                          echo "Ended ----------- \n\n";
echo "rake db:migrate RAILS_ENV=test \n";           shell_exec("rake db:migrate RAILS_ENV=test");           echo "Ended ----------- \n\n";
echo "rake truncate \n";                            shell_exec("rake truncate");                            echo "Ended ----------- \n\n";
echo "rake scenarios:load NAME=bootstrap \n";       shell_exec("rake scenarios:load NAME=bootstrap");       echo "Ended ----------- \n\n";

?>
<?php 

echo "rake db:drop:all \n";                         shell_exec("rake db:drop:all");                         echo "Ended ----------- \n\n";
echo "rake eol:db:create:all \n";                   shell_exec("rake eol:db:create:all");                   echo "Ended ----------- \n\n";
echo "rake eol:db:create:all RAILS_ENV=test \n";    shell_exec("rake eol:db:create:all RAILS_ENV=test");    echo "Ended ----------- \n\n";
echo "rake db:migrate \n";                          shell_exec("rake db:migrate");                          echo "Ended ----------- \n\n";
echo "rake db:migrate RAILS_ENV=test \n";           shell_exec("rake db:migrate RAILS_ENV=test");           echo "Ended ----------- \n\n";
echo "rake truncate \n";                            shell_exec("rake truncate");                            echo "Ended ----------- \n\n";
echo "rake scenarios:load NAME=bootstrap \n";       shell_exec("rake scenarios:load NAME=bootstrap");       echo "Ended ----------- \n\n";

?>