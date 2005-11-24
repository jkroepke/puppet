if __FILE__ == $0
    $:.unshift '..'
    $:.unshift '../../lib'
    $:.unshift "../../../../language/trunk/lib"
    $puppetbase = "../../../../language/trunk"
end

require 'puppet'
require 'cgi'
require 'test/unit'
require 'fileutils'
require 'puppettest'


class TestFileIgnoreSources < Test::Unit::TestCase
	include FileTesting
   
    def setup
        super
        begin
            initstorage
        rescue
            system("rm -rf %s" % Puppet[:checksumfile])
        end
    end

    def teardown
        super
        clearstorage
    end

#This is not needed unless using md5 (correct me if I'm wrong)
    def initstorage
        Puppet::Storage.init
        Puppet::Storage.load
    end

    def clearstorage
        Puppet::Storage.store
        Puppet::Storage.clear
    end

    def test_ignore_simple_source

        #Temp directory to run tests in
        path = tempfile()
        @@tmpfiles.push path

        #source directory
        sourcedir = "sourcedir"
        sourcefile1 = "sourcefile1"
        sourcefile2 = "sourcefile2"

        frompath = File.join(path,sourcedir)
        FileUtils.mkdir_p frompath

        topath = File.join(path,"destdir")
        FileUtils.mkdir topath

        #initialize variables before block
        tofile = nil
        trans = nil

        #create source files

        File.open(File.join(frompath,sourcefile1), 
          File::WRONLY|File::CREAT|File::APPEND) { |of|
            of.puts "yayness"
        }
      
        File.open(File.join(frompath,sourcefile2), 
          File::WRONLY|File::CREAT|File::APPEND) { |of|
            of.puts "even yayer"
        }
      

        #makes Puppet file Object
        assert_nothing_raised {
            tofile = Puppet::Type::PFile.create(
                :name => topath,
                :source => frompath,
                :recurse => true,                             
                :ignore => "sourcefile2"                            
            )
        }

        #make a component and adds the file
        comp = Puppet::Type::Component.create(
            :name => "component"
        )
        comp.push tofile

        #make, evaluate transaction and sync the component
        assert_nothing_raised {
            trans = comp.evaluate
        }
        assert_nothing_raised {
            trans.evaluate
        }
  
      
        #topath should exist as a directory with sourcedir as a directory
       
        #This file should exist
        assert(FileTest.exists?(File.join(topath,sourcefile1)))

        #This file should not
        assert(!(FileTest.exists?(File.join(topath,sourcefile2))))
     
        Puppet::Type.allclear
    end

    def test_ignore_with_wildcard
        #Temp directory to run tests in
        path = tempfile()
        @@tmpfiles.push path

        #source directory
        sourcedir = "sourcedir"
        subdir = "subdir"
        subdir2 = "subdir2"
        sourcefile1 = "sourcefile1"
        sourcefile2 = "sourcefile2"

        frompath = File.join(path,sourcedir)
        FileUtils.mkdir_p frompath
        
        FileUtils.mkdir_p(File.join(frompath, subdir))
        FileUtils.mkdir_p(File.join(frompath, subdir2))
        dir =  Dir.glob(File.join(path,"**/*"))

        topath = File.join(path,"destdir")
        FileUtils.mkdir topath

        #initialize variables before block
        tofile = nil
        trans = nil

        #create source files
               
        dir.each { |dir|       
            File.open(File.join(dir,sourcefile1), 
             File::WRONLY|File::CREAT|File::APPEND) { |of|
                of.puts "yayness"
            }
      
            File.open(File.join(dir,sourcefile2), 
             File::WRONLY|File::CREAT|File::APPEND) { |of|
              of.puts "even yayer"
            }
      
        }

        #makes Puppet file Object
        assert_nothing_raised {
            tofile = Puppet::Type::PFile.create(
                :name => topath,
                :source => frompath,
                :recurse => true,                             
                :ignore => "*2"                            
            )
        }

        #make a component and adds the file
        comp = Puppet::Type::Component.create(
            :name => "component"
        )
        comp.push tofile

        #make, evaluate transaction and sync the component
        assert_nothing_raised {
            trans = comp.evaluate
        }
        assert_nothing_raised {
            trans.evaluate
        }
              
        #topath should exist as a directory with sourcedir as a directory
       
        #This file should exist
        assert(FileTest.exists?(File.join(topath,sourcefile1)))
        assert(FileTest.exists?(File.join(topath,subdir)))
        assert(FileTest.exists?(File.join(File.join(topath,subdir),sourcefile1)))
        #This file should not
        assert(!(FileTest.exists?(File.join(topath,sourcefile2))))
        assert(!(FileTest.exists?(File.join(topath,subdir2))))
        assert(!(FileTest.exists?(File.join(File.join(topath,subdir),sourcefile2))))
        Puppet::Type.allclear

    end

    def test_ignore_array
        #Temp directory to run tests in
        path = tempfile()
        @@tmpfiles.push path

        #source directory
        sourcedir = "sourcedir"
        subdir = "subdir"
        subdir2 = "subdir2"
        subdir3 = "anotherdir"
        sourcefile1 = "sourcefile1"
        sourcefile2 = "sourcefile2"

        frompath = File.join(path,sourcedir)
        FileUtils.mkdir_p frompath
        
        FileUtils.mkdir_p(File.join(frompath, subdir))
        FileUtils.mkdir_p(File.join(frompath, subdir2))
        FileUtils.mkdir_p(File.join(frompath, subdir3))
        sourcedir =  Dir.glob(File.join(path,"**/*"))

        topath = File.join(path,"destdir")
        FileUtils.mkdir topath

        #initialize variables before block
        tofile = nil
        trans = nil

        #create source files
       

    
        sourcedir.each { |dir|       
            File.open(File.join(dir,sourcefile1), 
             File::WRONLY|File::CREAT|File::APPEND) { |of|
                of.puts "yayness"
            }
      
            File.open(File.join(dir,sourcefile2), 
             File::WRONLY|File::CREAT|File::APPEND) { |of|
              of.puts "even yayer"
            }
      
        }


        #makes Puppet file Object
        assert_nothing_raised {
            tofile = Puppet::Type::PFile.create(
                :name => topath,
                :source => frompath,
                :recurse => true,
                :ignore => ["*2", "an*"]                            
               # :ignore => ["*2", "an*", "nomatch"]                            
            )
        }

        #make a component and adds the file
        comp = Puppet::Type::Component.create(
            :name => "component"
        )
        comp.push tofile

        #make, evaluate transaction and sync the component
        assert_nothing_raised {
            trans = comp.evaluate
        }
        assert_nothing_raised {
            trans.evaluate
        }

        #topath should exist as a directory with sourcedir as a directory

        # This file should exist
        # proper files in destination
        assert(FileTest.exists?(File.join(topath,sourcefile1)), "file1 not in destdir")
        assert(FileTest.exists?(File.join(topath,subdir)), "subdir1 not in destdir")
        assert(FileTest.exists?(File.join(File.join(topath,subdir),sourcefile1)), "file1 not in subdir")
        # proper files in source 
        assert(FileTest.exists?(File.join(frompath,subdir)), "subdir not in source")
        assert(FileTest.exists?(File.join(frompath,subdir2)), "subdir2 not in source")
        assert(FileTest.exists?(File.join(frompath,subdir3)), "subdir3 not in source")

        # This file should not
        assert(!(FileTest.exists?(File.join(topath,sourcefile2))), "file2 in dest")
        assert(!(FileTest.exists?(File.join(topath,subdir2))), "subdir2 in dest")
        assert(!(FileTest.exists?(File.join(topath,subdir3))), "anotherdir in dest")
        assert(!(FileTest.exists?(File.join(File.join(topath,subdir),sourcefile2))), "file2 in dest/sub")
        

        Puppet::Type.allclear

    end

end

# $Id$
