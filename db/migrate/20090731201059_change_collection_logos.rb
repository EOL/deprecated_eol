class ChangeCollectionLogos < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    execute('alter table collections add `logo_cache_url` bigint(20) unsigned default NULL after `logo_url`')
    
    execute("update collections set logo_cache_url=6385 where logo_url='itis.png'")
    execute("update collections set logo_cache_url=3601 where logo_url='algaebase.png'")
    execute("update collections set logo_cache_url=5027 where logo_url='ildis.png'")
    execute("update collections set logo_cache_url=9498 where logo_url='fishbase.png'")
    execute("update collections set logo_cache_url=4937 where logo_url='fungorum.png'")
    execute("update collections set logo_cache_url=4130 where logo_url='colp.png'")
    execute("update collections set logo_cache_url=5458 where logo_url='nz.png'")
    execute("update collections set logo_cache_url=1305 where logo_url='ncbi.png'")
    execute("update collections set logo_cache_url=9433 where logo_url='microscope.png'")
    execute("update collections set logo_cache_url=5404 where logo_url='grin.png'")
    execute("update collections set logo_cache_url=6852 where logo_url='arach.png'")
    execute("update collections set logo_cache_url=3810 where logo_url='marbef.png'")
    execute("update collections set logo_cache_url=6832 where logo_url='usdaplants.png'")
    execute("update collections set logo_cache_url=7810 where logo_url='antweb.png'")
    execute("update collections set logo_cache_url=2406 where logo_url='amphibia.png'")
    execute("update collections set logo_cache_url=8685 where logo_url='adw.png'")
    execute("update collections set logo_cache_url=1880 where logo_url='tropicos.png'")
    execute("update collections set logo_cache_url=2938 where logo_url='biolib.png'")
    execute("update collections set logo_cache_url=7391 where logo_url='hns.png'")
    execute("update collections set logo_cache_url=5486 where logo_url='europaea.png'")
    execute("update collections set logo_cache_url=8567 where logo_url='gbif.png'")
    execute("update collections set logo_cache_url=5801 where logo_url='morphbank.png'")
    execute("update collections set logo_cache_url=5100 where logo_url='tol.png'")
    execute("update collections set logo_cache_url=5019 where logo_url='redlist.png'")
    execute("update collections set logo_cache_url=5630 where logo_url='ubio.png'")
    execute("update collections set logo_cache_url=5230 where logo_url='obis.png'")
    execute("update collections set logo_cache_url=7434 where logo_url='abbi.png'")
    execute("update collections set logo_cache_url=6805 where logo_url='fishbol.png'")
    execute("update collections set logo_cache_url=1923 where logo_url='polarbol.png'")
    execute("update collections set logo_cache_url=9355 where logo_url='marbol.png'")
    execute("update collections set logo_cache_url=2244 where logo_url='wikipedia.png'")
    execute("update collections set logo_cache_url=8456 where logo_url='bold.png'")
    execute("update collections set logo_cache_url=1904 where logo_url='arkive.png'")
    execute("update collections set logo_cache_url=8987 where logo_url='xenocanto.png'")
    execute("update collections set logo_cache_url=3187 where logo_url='ligercat.png'")
    
    remove_column :collections, :logo_url
  end

  def self.down
    execute('alter table collections add `logo_url` varchar(255) character set ascii NOT NULL after `link`')
    
    execute("update collections set logo_url='itis.png' where logo_cache_url=6385")
    execute("update collections set logo_url='algaebase.png' where logo_cache_url=3601")
    execute("update collections set logo_url='ildis.png' where logo_cache_url=5027")
    execute("update collections set logo_url='fishbase.png' where logo_cache_url=9498")
    execute("update collections set logo_url='fungorum.png' where logo_cache_url=4937")
    execute("update collections set logo_url='colp.png' where logo_cache_url=4130")
    execute("update collections set logo_url='nz.png' where logo_cache_url=5458")
    execute("update collections set logo_url='ncbi.png' where logo_cache_url=1305")
    execute("update collections set logo_url='microscope.png' where logo_cache_url=9433")
    execute("update collections set logo_url='grin.png' where logo_cache_url=5404")
    execute("update collections set logo_url='arach.png' where logo_cache_url=6852")
    execute("update collections set logo_url='marbef.png' where logo_cache_url=3810")
    execute("update collections set logo_url='usdaplants.png' where logo_cache_url=6832")
    execute("update collections set logo_url='antweb.png' where logo_cache_url=7810")
    execute("update collections set logo_url='amphibia.png' where logo_cache_url=2406")
    execute("update collections set logo_url='adw.png' where logo_cache_url=8685")
    execute("update collections set logo_url='tropicos.png' where logo_cache_url=1880")
    execute("update collections set logo_url='biolib.png' where logo_cache_url=2938")
    execute("update collections set logo_url='hns.png' where logo_cache_url=7391")
    execute("update collections set logo_url='europaea.png' where logo_cache_url=5486")
    execute("update collections set logo_url='gbif.png' where logo_cache_url=8567")
    execute("update collections set logo_url='morphbank.png' where logo_cache_url=5801")
    execute("update collections set logo_url='tol.png' where logo_cache_url=5100")
    execute("update collections set logo_url='redlist.png' where logo_cache_url=5019")
    execute("update collections set logo_url='ubio.png' where logo_cache_url=5630")
    execute("update collections set logo_url='obis.png' where logo_cache_url=5230")
    execute("update collections set logo_url='abbi.png' where logo_cache_url=7434")
    execute("update collections set logo_url='fishbol.png' where logo_cache_url=6805")
    execute("update collections set logo_url='polarbol.png' where logo_cache_url=1923")
    execute("update collections set logo_url='marbol.png' where logo_cache_url=9355")
    execute("update collections set logo_url='wikipedia.png' where logo_cache_url=2244")
    execute("update collections set logo_url='bold.png' where logo_cache_url=8456")
    execute("update collections set logo_url='arkive.png' where logo_cache_url=1904")
    execute("update collections set logo_url='xenocanto.png' where logo_cache_url=8987")
    execute("update collections set  logo_url='ligercat.png' where logo_cache_url=3187")
    
    remove_column :collections, :logo_cache_url
  end
end
