/bin/bash -l -i -c "echo '*** starting Billing-Logic build ***' && \
  billing && \
  source $HOME/.rvm/scripts/rvm && \
  source .rvmrc && \
  bundle exec rake ci"
