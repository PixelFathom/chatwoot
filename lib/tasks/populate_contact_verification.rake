namespace :contacts do
  desc 'Populate is_verified column for existing contacts based on verification criteria'
  task populate_verification: :environment do
    puts "Starting to populate is_verified column for contacts..."
    
    total_contacts = Contact.count
    puts "Total contacts to process: #{total_contacts}"
    
    batch_size = 1000
    updated_count = 0
    
    Contact.find_each(batch_size: batch_size) do |contact|
      # Check if contact should be verified using the same logic as model
      should_be_verified = contact.email.present? || 
                          contact.phone_number.present? || 
                          contact.identifier.present? || 
                          (contact.additional_attributes.present? && contact.additional_attributes['company_name'].present?)
      
      # Update only if current value is different (avoid unnecessary updates)
      if contact.is_verified != should_be_verified
        Contact.where(id: contact.id).update_all(is_verified: should_be_verified)
        updated_count += 1
      end
      
      # Progress indicator
      if updated_count % 100 == 0
        puts "Updated #{updated_count} contacts..."
      end
    end
    
    puts "✅ Completed! Updated #{updated_count} out of #{total_contacts} contacts."
    puts "Verification summary:"
    puts "- Verified contacts: #{Contact.where(is_verified: true).count}"
    puts "- Unverified contacts: #{Contact.where(is_verified: false).count}"
  end
  
  desc 'Show contact verification statistics'
  task verification_stats: :environment do
    total = Contact.count
    verified = Contact.where(is_verified: true).count
    unverified = Contact.where(is_verified: false).count
    
    puts "📊 Contact Verification Statistics:"
    puts "Total contacts: #{total}"
    puts "Verified contacts: #{verified} (#{(verified.to_f / total * 100).round(2)}%)"
    puts "Unverified contacts: #{unverified} (#{(unverified.to_f / total * 100).round(2)}%)"
    puts ""
    puts "Verification criteria breakdown:"
    puts "- With email: #{Contact.where.not(email: [nil, '']).count}"
    puts "- With phone: #{Contact.where.not(phone_number: [nil, '']).count}"
    puts "- With identifier: #{Contact.where.not(identifier: [nil, '']).count}"
    puts "- With company_name: #{Contact.where("additional_attributes->>'company_name' IS NOT NULL AND additional_attributes->>'company_name' != ''").count}"
  end
end