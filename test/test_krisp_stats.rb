require 'minitest/autorun'
require 'stringio'
load File.expand_path('../krisp-stats', __dir__)

class TestKrispStats < Minitest::Test
  ROOT = File.expand_path('..', __dir__)

  def words(n)
    (['word'] * n).join(' ')
  end

  def test_parse_headers_and_words
    turns = KrispStats.parse("Ann | 00:00\nHello there friend.\n \nmore - text\nBob B | 1:02:03\nOk.\n")
    assert_equal ['Ann', 'Bob B'], turns.map(&:speaker)
    assert_equal [0, 3723], turns.map(&:start)
    assert_equal [5, 1], turns.map(&:words)
  end

  def test_gap_based_durations
    text = "A | 00:00\n#{words(30)}\nB | 00:10\n#{words(30)}\nA | 00:20\n#{words(30)}\n"
    r = KrispStats.analyze(text)
    a = r[:stats].find { |s| s.name == 'A' }
    b = r[:stats].find { |s| s.name == 'B' }
    assert_in_delta 20.0, a.seconds, 0.01 # 10s gap + last turn at 180 wpm => 10s
    assert_in_delta 10.0, b.seconds, 0.01
    assert_in_delta 100.0, r[:stats].map(&:percent).inject(:+), 0.001
  end

  def test_long_pause_is_capped
    text = "A | 00:00\n#{words(30)}\nB | 00:10\n#{words(30)}\n" \
           "A | 00:20\n#{words(30)}\nB | 00:30\nyes\nA | 05:00\n#{words(30)}\n"
    r = KrispStats.analyze(text)
    capped = r[:turns].select(&:capped)
    assert_equal 1, capped.size
    assert_equal 'B', capped.first.speaker
    assert_operator capped.first.duration, :<, 5
    assert capped.first.duration > 0
    assert r[:turns].last.estimated
  end

  def test_no_turns_raises
    assert_raises(ArgumentError) { KrispStats.analyze("just text\n") }
  end

  def test_fmt_time
    assert_equal '0:05', KrispStats.fmt_time(5)
    assert_equal '12:34', KrispStats.fmt_time(754)
    assert_equal '1:00:01', KrispStats.fmt_time(3601)
  end

  def test_sample_transcripts
    Dir[File.join(ROOT, 'transcript*.txt')].each do |f|
      r = KrispStats.analyze(File.read(f, encoding: 'UTF-8'))
      assert_in_delta 100.0, r[:stats].map(&:percent).inject(:+), 0.001
      assert_operator r[:total], :<=, r[:span] + 0.001
      assert_operator r[:total], :>, r[:span] * 0.8, "#{f}: too much time trimmed"
    end
  end

  def test_cli_stdin_and_no_color
    out = StringIO.new
    status = KrispStats.run(['--no-color'], stdin: StringIO.new("A | 00:00\nhi there\nB | 00:04\nok\n"),
                                            stdout: out, stderr: StringIO.new)
    assert_equal 0, status
    refute_includes out.string, "\e["
    assert_match(/A\s+0:04\s+\d+\.\d%/, out.string)
  end
end
