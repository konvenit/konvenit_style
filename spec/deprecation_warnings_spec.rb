require "spec_helper"

RSpec.describe "Deprecation warnings in the specs" do
  it "raises on a Ruby warning of the deprecated category" do
    expect { Warning.warn("old syntax", category: :deprecated) }
      .to raise_error(DeprecationWarningError, /old syntax/)
  end

  it "raises on a gem warning announcing a deprecation" do
    expect { warn("[DEPRECATION NOTICE] old setting") }
      .to raise_error(DeprecationWarningError, /old setting/)
  end

  it "prints any other warning" do
    expect { warn("disk almost full") }.to output(/disk almost full/).to_stderr
  end
end
