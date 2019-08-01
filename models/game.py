
ROCK = 'ROCK'
PAPER = 'PAPER'
SCISSORS = 'SCISSORS'


MOVES_BEAT = {
     SCISSORS :PAPER,
     PAPER: ROCK,
     ROCK :SCISSORS,
}

class Game:
    def __init__(self, user1, user2):
        self.user1 =user1
        self.user2 = user2
        user1.game = self
        user2.game = self
        user1.status = 'PLAYING'
        user2.status = 'PLAYING'
        self.reset()

    def reset(self):
        self.user1_choice = None
        self.user2_choice = None
        
    def play(self, user, move):
        if move not in (ROCK, PAPER, SCISSORS):
            return

        if user.rowid == self.user1.rowid:
            self.user1_choice = move
        elif user.rowid == self.user2.rowid:
            self.user2_choice = move
    
    def is_over(self):
        return self.user1_choice is not None and self.user2_choice is not None 
    
    def is_tie(self):
        return self.user1_choice == self.user2_choice
        
    def get_winner_loser(self):
        if self.is_tie():
            return None
        if MOVES_BEAT[self.user1_choice] == self.user2_choice:
            return (self.user1, self.user2)
        return (self.user2, self.user1)

    def quit(self):
        self.user1.game = None
        self.user2.game = None
        self.user1.status = 'AVAILABLE'
        self.user2.status = 'AVAILABLE'
            
    __del__ = quit