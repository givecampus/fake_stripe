require 'spec_helper'

describe 'Stub app Payout state branching' do
  it 'returns in_transit for a default payout id' do
    payout = Stripe::Payout.retrieve('po_1GkvSj2eZvKYlo2C0xOmaM51')

    expect(payout.status).to eq('in_transit')
  end

  it 'returns paid for ids prefixed with po_paid_' do
    payout = Stripe::Payout.retrieve('po_paid_test123')

    expect(payout.status).to eq('paid')
    expect(payout.reconciliation_status).to eq('completed')
  end

  it 'returns failed for ids prefixed with po_failed_' do
    payout = Stripe::Payout.retrieve('po_failed_test123')

    expect(payout.status).to eq('failed')
    expect(payout.failure_code).to eq('account_closed')
    expect(payout.failure_message).to include('bank account has been closed')
  end

  it 'returns canceled for ids prefixed with po_canceled_' do
    payout = Stripe::Payout.retrieve('po_canceled_test123')

    expect(payout.status).to eq('canceled')
  end

  it 'cancel returns a canceled status instead of in_transit' do
    payout = Stripe::Payout.cancel('po_1GkvSj2eZvKYlo2C0xOmaM51')

    expect(payout.status).to eq('canceled')
  end
end
