class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  after_action do
    GC.start
    stat = GC.stat
    logger.info "Heap slots: #{stat[:heap_live_slots]}/#{stat[:heap_available_slots]}"
  end
end
