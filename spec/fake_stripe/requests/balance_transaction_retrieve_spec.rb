require 'spec_helper'

describe 'Stub app BalanceTransaction retrieve' do
  it 'serves the modern /v1/balance_transactions/:id path used by stripe-ruby >= 5' do
    txn = Stripe::BalanceTransaction.retrieve('txn_19XJJ02eZvKYlo2ClwuJ1rbA')

    expect(txn.id).to eq('txn_19XJJ02eZvKYlo2ClwuJ1rbA')
    expect(txn.reporting_category).to eq('charge')
  end
end
