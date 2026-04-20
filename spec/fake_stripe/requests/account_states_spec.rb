require 'spec_helper'

describe 'Stub app Account state branching' do
  it 'returns the not-yet-verified fixture for a default account id' do
    account = Stripe::Account.retrieve('acct_1032D82eZvKYlo2C')

    expect(account.payouts_enabled).to eq(false)
    expect(account.charges_enabled).to eq(false)
  end

  it 'returns a verified account for ids prefixed with acct_ready_' do
    account = Stripe::Account.retrieve('acct_ready_test123')

    expect(account.payouts_enabled).to eq(true)
    expect(account.charges_enabled).to eq(true)
    expect(account.requirements.currently_due).to eq([])
  end

  it 'exposes the basil-era controller object on the ready fixture' do
    account = Stripe::Account.retrieve('acct_ready_test123')

    expect(account.controller.is_controller).to eq(true)
    expect(account.controller.type).to eq('account')
  end

  it 'exposes future_requirements on the ready fixture' do
    account = Stripe::Account.retrieve('acct_ready_test123')

    expect(account.future_requirements.currently_due).to eq([])
  end
end
