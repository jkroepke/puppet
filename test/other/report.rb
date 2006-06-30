if __FILE__ == $0
    $:.unshift '..'
    $:.unshift '../../lib'
    $puppetbase = "../.."
end

require 'puppet'
require 'puppet/transaction/report'
require 'puppettest'
require 'test/unit'

class TestReports < Test::Unit::TestCase
	include TestPuppet

    # Make sure we can use reports as log destinations.
    def test_reports_as_log_destinations
        report = nil
        assert_nothing_raised {
            report = Puppet::Transaction::Report.new
        }

        assert_nothing_raised {
            Puppet::Log.newdestination(report)
        }

        # Now make a file for testing logging
        file = Puppet::Type.newfile(:path => tempfile(), :ensure => "file")

        log = nil
        assert_nothing_raised {
            log = file.log "This is a message, yo"
        }

        assert(report.logs.include?(log), "Report did not get log message")

        log = Puppet.info "This is a non-sourced message"

        assert(! report.logs.include?(log), "Report got log message")

        assert_nothing_raised {
            Puppet::Log.close(report)
        }

        log = file.log "This is another message, yo"

        assert(! report.logs.include?(log), "Report got log message after close")
    end

    def test_newmetric
        report = nil
        assert_nothing_raised {
            report = Puppet::Transaction::Report.new
        }

        assert_nothing_raised {
            report.newmetric(:mymetric,
                :total => 12,
                :done => 6
            )
        }
    end

    def test_rrdgraph_report
        Puppet.config.use(:metrics)
        # First do some work
        objects = []
        25.times do |i|
            file = tempfile()

            # Make every third file
            File.open(file, "w") { |f| f.puts "" } if i % 3 == 0

            objects << Puppet::Type.newfile(
                :path => file,
                :ensure => "file"
            )
        end

        comp = newcomp(*objects)

        trans = nil
        assert_nothing_raised("Failed to create transaction") {
            trans = comp.evaluate
        }

        assert_nothing_raised("Failed to evaluate transaction") {
            trans.evaluate
        }

        code = Puppet::Server::Report.report("rrdgraph")

        assert_nothing_raised {
            code.call(trans.report)
        }
    end
end

# $Id$
