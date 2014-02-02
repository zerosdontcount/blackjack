require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do
  def total(cards)
    arr = cards.map{|item| item[0]}
    total = 0
    arr.each do |card|
      if card == "ace"
        total += 11
      else
        total += card.to_i == 0 ? 10 : card
      end
    end    
    #correct for Aces
      arr.each do |card|
        if total > 21 && card == "ace" 
          total -= 10
        end
      end
    total
  end

  def card_image(card) #nested array to image
    suit = card[1]
    value = card[0]
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card'>"
  end
end  

before do
  @hs_buttons = true #hit or stay buttons
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    erb :new_player
  end
end

get '/new_player' do
  erb :new_player
end

post '/start_game' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb :new_player
  end
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do  
  # create deck & shuffle
  suits = ["clubs", "diamonds", "hearts", "spades"]
  values = [2, 3, 4, 5, 6, 7, 8, 9, 10, "jack", "queen", "king", "ace"]
  session[:deck] = values.product(suits).shuffle!
  #deal cards
  session[:dealer_hand] = []
  session[:player_hand] = []
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop

  if total(session[:player_hand]) == 21
    @success = "You have Blackjack!"
    @stay = true
    @hs_buttons = false
    @dealer_hit = false
    redirect '/game/dealer'
  end 
  erb :game
end

post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop
  if total(session[:player_hand]) == 21
    @success = "You have 21!"
    @hs_buttons = false
    @dealer_hit = true
  elsif total(session[:player_hand]) > 21
    @error = "Sorry, you have busted!"
    @hs_buttons = false
    @dealer_hit = false
    redirect '/game/dealer'
  end 
    erb :game
end

post '/game/player/stay' do
  @success = "You have chosen to Stay"
  @hs_buttons = false
  redirect '/game/dealer'
  @stay = true
end

get '/game/dealer' do
  @hs_buttons = false
  session[:dealer_hand] << session[:deck].pop
  if total(session[:dealer_hand]) == 21 || total(session[:player_hand]) == 21
    redirect '/game/winner'
  elsif total(session[:dealer_hand]) > 16
    @dealer_hit = false
    redirect '/game/winner'
  elsif total(session[:dealer_hand]) <= 16 && total(session[:player_hand]) <= 21
    @dealer_hit = true  
  else
    redirect '/game/winner'
  end
  erb :game
end

post '/game/dealer/hit' do
  @hs_buttons = false
  if total(session[:player_hand]) == 21 && session[:player_hand].size == 2
    @playerBJ = true
  else
    @playerBJ = false
  end
  
  if total(session[:player_hand]) > 21 || @playerBJ == true
    session[:dealer_hand] << session[:deck].pop
    redirect '/game/winner'
  else
    if total(session[:dealer_hand]) < 17 && @playerBJ == false
      @dealer_hit = true
      session[:dealer_hand] << session[:deck].pop
    elsif total(session[:dealer_hand]) > 21
      @success = "Dealer has busted!"
      @dealer_hit = false
    elsif total(session[:dealer_hand]) >= 17
      @dealer_hit = false
    elsif total(session[:dealer_hand]) == 21 && session[:dealer_hand].size == 2
      @error = "Dealer has blackjack!"
    elsif @stay == true && total(session[:dealer_hand]) > 17
      redirect '/game/winner'
    elsif total(session[:player_hand]) > 21
      redirect '/game/winner'
    end
  end
  if total(session[:dealer_hand]) > 16
    redirect '/game/winner'
  end
  erb :game
end

get '/game/winner' do
  @hs_buttons = false
  #check for dealer BJ
  if total(session[:dealer_hand]) == 21 && session[:dealer_hand].size == 2
    @dealerBJ = true
  else 
    @dealerBJ = false
  end
  #check for player BJ
  if total(session[:player_hand]) == 21 && session[:player_hand].size == 2
    @playerBJ = true 
  else
    @playerBJ = false
  end

  case true
    when total(session[:player_hand]) > 21 
      @error = "Sorry, you have busted! Dealer wins with a total of #{total(session[:dealer_hand])}"
    when total(session[:player_hand]) > total(session[:dealer_hand]) && total(session[:player_hand]) <= 21 && @playerBJ == false
      @success = "You win! You beat the dealer #{total(session[:player_hand])} to #{total(session[:dealer_hand])}"
    when @playerBJ == true
      @success = "Blackjack! You win!"
    when total(session[:player_hand]) < total(session[:dealer_hand]) && @dealerBJ == false && total(session[:dealer_hand]) <= 21
      @error = "Sorry, dealer beats you #{total(session[:dealer_hand])} to #{total(session[:player_hand])}"
    when total(session[:dealer_hand]) > 21
      @success = "Dealer busted, you win with #{total(session[:player_hand])}!"
    when @dealerBJ == true && total(session[:player_hand]) == 21 && session[:player_hand].size != 2
      @error = "Sorry, Blackjack beats multicard 21. You lose."
    when @dealerBJ == true && @playerBJ = false
      @error = "Sorry, Dealer beats you with Blackjack!"
    when total(session[:player_hand]) == total(session[:dealer_hand])  
      @success = "It's a push!"
    when @dealerBJ == true && @playerBJ == false
      @error = "Sorry, Dealer beats you with a Blackjack"
  end
  @play = true
  erb :game
end

post '/game/another' do
  redirect '/game'
end















