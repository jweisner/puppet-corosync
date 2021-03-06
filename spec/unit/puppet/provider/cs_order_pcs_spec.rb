require 'spec_helper'

describe Puppet::Type.type(:cs_order).provider(:pcs) do
  before do
    described_class.stubs(:command).with(:pcs).returns 'pcs'
    described_class.expects(:block_until_ready).returns(nil)
  end

  let :test_cib do
    <<-EOS
      <cib>
      <configuration>
        <constraints>
          <rsc_order first="nul-messagebus" first-action="start" id="nul-messagebus_before_nul-interface-2" kind="Mandatory" symmetrical="true" then="nul-interface-2" then-action="start"/>
          <rsc_order first="nul2-messagebus" first-action="promote" id="nul2-messagebus_before_nul-interface-2b" kind="Optional" symmetrical="false" then="nul-interface-2b" then-action="start"/>
        </constraints>
      </configuration>
      </cib>
    EOS
  end

  let :instances do
    Puppet::Util::Execution.expects(:execute).with(%w(pcs cluster cib), failonfail: true, combine: true).at_least_once.returns(
      Puppet::Util::Execution::ProcessOutput.new(test_cib, 0)
    )
    described_class.instances
  end

  context 'when getting instances' do
    it 'has an instance for each <rsc_order>' do
      expect(instances.count).to eq(2)
    end

    describe 'each instance' do
      let :instance do
        instances.first
      end

      it "should be a kind of #{described_class.name}" do
        expect(instance).to be_a_kind_of(described_class)
      end

      it "is named by the <primitive>'s id attribute" do
        expect(instance.name).to eq('nul-messagebus_before_nul-interface-2')
      end
    end
    describe 'first instance' do
      let :instance do
        instances.first
      end

      it 'has attributes' do
        expect(instance.first).to eq('nul-messagebus:start')
        expect(instance.second).to eq('nul-interface-2:start')
        expect(instance.kind).to eq('Mandatory')
        expect(instance.symmetrical).to eq(true)
      end
    end

    describe 'second instance' do
      let :instance do
        instances[1]
      end

      it 'has attributes' do
        expect(instance.first).to eq('nul2-messagebus:promote')
        expect(instance.second).to eq('nul-interface-2b:start')
        expect(instance.kind).to eq('Optional')
        expect(instance.symmetrical).to eq(false)
      end
    end
  end
end
