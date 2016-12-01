//
//  OpenGLWrapper.m
//  Checkers-AR
//
//  Created by Nikolas Chaconas on 11/6/16.
//  Copyright © 2016 Nikolas Chaconas. All rights reserved.
//

#import "OpenCVWrapper.hpp"
#include <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

#define DEGREES_TO_RADIANS(x) (3.14159265358979323846 * x / 180.0)
#define NUM_CHECKER_PIECES 11

@implementation OpenGLWrapper {
    OpenCVWrapper *calibrator;
    GLKView *view;
    GLKBaseEffect *effect;
    EAGLContext * context;
    double width, height, screen_width, screen_height, x, y;
    
    GLuint viewRenderBuffer, viewFrameBuffer, colorRenderBuffer, depthRenderBuffer;
    bool wait;
    clock_t prevTimeStamp;
    std::vector<checkerPiece> grayPieces;
    std::vector<checkerPiece> redPieces;
    int pieceSelectedIndex;
    checkerPiece selectedPiece;
    std::vector<validMove> moves;
    int turn;
    int erasedCheckerIndex;
    bool jump;
    bool jumpAvailable;
    bool inContinuousJump;
    int team0Score;
    int team1Score;
    double suggestPieceX;
    double suggestPieceY;
    double suggestMoveX;
    double suggestMoveY;
}

-(void) setParams:(GLKBaseEffect*)eff cont:(EAGLContext*)Contextcont width:(double)_width height:(double)_height {
    effect = eff;
    context = Contextcont;

    width = _width;
    height = _height;
    
    wait = false;
    prevTimeStamp = 0;
    pieceSelectedIndex = -1;
    //grey begins
    turn = 0;
    std::cout << "width is " << width << " and height is " << height << std::endl;
    if(!viewRenderBuffer)
        glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    [self initializeCheckerPieces];
//    [self createFramebuffer];
}

-(int) getTeam0Score {
    return team0Score;
}
-(int) getTeam1Score {
    return team1Score;
}

-(void) getValidForwardJumpMoves{
    bool occupiedByOpp = false;
    bool occupied = false;
    double newCoorX = 0;
    double newCoorY = 0;
    double diagonalX = -1;
    double diagonalY = -1;
    checkerPiece *piece;
    validMove move;
    for (int i = 0; i < 2; i++) {
        newCoorX = diagonalX + selectedPiece.x;
        newCoorY = diagonalY + selectedPiece.y;
        if (newCoorX >= 0 && newCoorX <= 6 && newCoorY >= 0 && newCoorY <= 8) {
            if (!turn) {
                for(int j = 0; j < redPieces.size(); j++) {
                    piece = &redPieces.at(j);
                    if(piece->x == newCoorX && piece->y == newCoorY) {
                        occupiedByOpp = true;
                        break;
                    }
                }
            } else {
                for(int j = 0; j < grayPieces.size(); j++) {
                    piece = &grayPieces.at(j);
                    if(piece->x == newCoorX && piece->y == newCoorY) {
                        occupiedByOpp = true;
                        break;
                    }
                }
            }
            if (occupiedByOpp) {
                newCoorX = diagonalX + newCoorX;
                newCoorY = diagonalY + newCoorY;
                if (newCoorX >= 0 && newCoorX <= 6 && newCoorY >= 0 && newCoorY <= 8) {
                    for(int j = 0; j < redPieces.size(); j++) {
                        piece = &redPieces.at(j);
                        if(piece->x == newCoorX && piece->y == newCoorY) {
                            occupied = true;
                            break;
                        }
                    }
                    for(int j = 0; j < grayPieces.size(); j++) {
                        piece = &grayPieces.at(j);
                        if(piece->x == newCoorX && piece->y == newCoorY) {
                            occupied = true;
                            break;
                        }
                    }
                    if (!occupied) {
                        move.x = newCoorX;
                        move.y = newCoorY;
                        move.checkersJumped = 1;
                        moves.push_back(move);
                        jumpAvailable = true;
                    }
                }
            }
        }
        occupied = false;
        occupiedByOpp = false;
        diagonalX = 1;
    }
}

-(void) getValidForwardMoves {
    bool occupied = false;
    double newCoorX = 0;
    double newCoorY = 0;
    double diagonalX = -1;
    double diagonalY = -1;
    checkerPiece *piece;
    validMove move;
    for (int i = 0; i < 2; i++) {
        newCoorX = diagonalX + selectedPiece.x;
        newCoorY = diagonalY + selectedPiece.y;
        if (newCoorX >= 0 && newCoorX <= 6 && newCoorY >= 0 && newCoorY <= 8) {
            for(int i = 0; i < redPieces.size(); i++) {
                piece = &redPieces.at(i);
                if(piece->x == newCoorX && piece->y == newCoorY) {
                    occupied = true;
                    break;
                }
            }
            for(int i = 0; i < grayPieces.size(); i++) {
                piece = &grayPieces.at(i);
                if(piece->x == newCoorX && piece->y == newCoorY) {
                    occupied = true;
                    break;
                }
            }
            if (!occupied) {
                move.x = newCoorX;
                move.y = newCoorY;
                move.checkersJumped = 0;
                moves.push_back(move);
            }
        }
        occupied = false;
        diagonalX = 1;
    }
}


-(void) getValidBackwardJumpMoves{
    bool occupiedByOpp = false;
    bool occupied = false;
    double newCoorX = 0;
    double newCoorY = 0;
    double diagonalX = -1;
    double diagonalY = 1;
    checkerPiece *piece;
    validMove move;
    for (int i = 0; i < 2; i++) {
        newCoorX = diagonalX + selectedPiece.x;
        newCoorY = diagonalY + selectedPiece.y;
        if (newCoorX >= 0 && newCoorX <= 6 && newCoorY >= 0 && newCoorY <= 8) {
            if (!turn) {
                for(int j = 0; j < redPieces.size(); j++) {
                    piece = &redPieces.at(j);
                    if(piece->x == newCoorX && piece->y == newCoorY) {
                        occupiedByOpp = true;
                        break;
                    }
                }
            } else {
                for(int j = 0; j < grayPieces.size(); j++) {
                    piece = &grayPieces.at(j);
                    if(piece->x == newCoorX && piece->y == newCoorY) {
                        occupiedByOpp = true;
                        break;
                    }
                }
            }
            if (occupiedByOpp) {
                newCoorX = diagonalX + newCoorX;
                newCoorY = diagonalY + newCoorY;
                if (newCoorX >= 0 && newCoorX <= 6 && newCoorY >= 0 && newCoorY <= 8) {
                    for(int j = 0; j < redPieces.size(); j++) {
                        piece = &redPieces.at(j);
                        if(piece->x == newCoorX && piece->y == newCoorY) {
                            occupied = true;
                            break;
                        }
                    }
                    for(int j = 0; j < grayPieces.size(); j++) {
                        piece = &grayPieces.at(j);
                        if(piece->x == newCoorX && piece->y == newCoorY) {
                            occupied = true;
                            break;
                        }
                    }
                    if (!occupied) {
                        move.x = newCoorX;
                        move.y = newCoorY;
                        move.checkersJumped = 1;
                        moves.push_back(move);
                        jumpAvailable = true;
                    }
                }
            }
        }
        occupied = false;
        occupiedByOpp = false;
        diagonalX = 1;
    }
}

-(void) getValidBackwardMoves{
    bool occupied = false;
    double newCoorX = 0;
    double newCoorY = 0;
    double diagonalX = -1;
    double diagonalY = 1;
    checkerPiece *piece;
    validMove move;
    for (int i = 0; i < 2; i++) {
        newCoorX = diagonalX + selectedPiece.x;
        newCoorY = diagonalY + selectedPiece.y;
        if (newCoorX >= 0 && newCoorX <= 6 && newCoorY >= 0 && newCoorY <= 8) {
            for(int i = 0; i < redPieces.size(); i++) {
                piece = &redPieces.at(i);
                if(piece->x == newCoorX && piece->y == newCoorY) {
                    occupied = true;
                    break;
                }
            }
            for(int i = 0; i < grayPieces.size(); i++) {
                piece = &grayPieces.at(i);
                if(piece->x == newCoorX && piece->y == newCoorY) {
                    occupied = true;
                    break;
                }
            }
            if (!occupied) {
                move.x = newCoorX;
                move.y = newCoorY;
                move.checkersJumped = 0;
                moves.push_back(move);
            }
        }
        occupied = false;
        diagonalX = 1;
    }
}

-(bool) isValidMove:(float) objx :(float) objy {
    checkerPiece *piece;
    int jumpedX, jumpedY;
    moves.clear();
    if (selectedPiece.crowned) {
        [self getValidForwardMoves];
        [self getValidBackwardMoves];
        [self getValidForwardJumpMoves];
        [self getValidBackwardJumpMoves];
    }
    else if (turn) {
        [self getValidForwardMoves];
        [self getValidForwardJumpMoves];
    } else {
        [self getValidBackwardMoves];
        [self getValidBackwardJumpMoves];
    }
    validMove *move;
    for (int i = 0; i < moves.size(); i++) {
        move = &moves.at(i);
        if (move->x == objx && move->y == objy) {
            if (std::abs(objx - selectedPiece.x) == 2) {
                if (objx < selectedPiece.x) jumpedX = objx + 1;
                else  jumpedX = objx - 1;
                if (objy < selectedPiece.y) jumpedY = objy + 1;
                else jumpedY = objy - 1;
                if (!turn) {
                    for(int j = 0; j < redPieces.size(); j++) {
                        piece = &redPieces.at(j);
                        if(piece->x == jumpedX && piece->y == jumpedY) {
                            erasedCheckerIndex = j;
                            break;
                        }
                    }
                } else {
                    for(int j = 0; j < grayPieces.size(); j++) {
                        piece = &grayPieces.at(j);
                        if(piece->x == jumpedX && piece->y == jumpedY) {
                            erasedCheckerIndex = j;
                            break;
                        }
                    }
                }
                jump = true;
            } else if (jumpAvailable) {
                return false;
            }
            if (jump && turn)
                team1Score++;
            if (jump && !turn)
                team0Score++;
            return true;
        }
    }
    return false;
}

-(bool) suggestMove {
    moves.clear();
    checkerPiece *piece;
    checkerPiece saveSelectedPiece = selectedPiece;
    int tempTeam0Score = team0Score;
    int tempTeam1Score = team1Score;
    int i;
    bool breakOut = false;
    if (!turn) {
        for(i = 0; i < grayPieces.size(); i++) {
            piece = &grayPieces.at(i);
            selectedPiece = *piece;
            for (int j = 0; j < 7; j++) {
                for (int k = 0; k < 9; k++) {
                    if ([self isValidMove:(float)j :(float)k] && [self jumpsAvailable]) {
                        suggestPieceX = piece->x;
                        suggestPieceY = piece->y;
                        suggestMoveX = (float)j;
                        suggestMoveY = (float)k;
                        breakOut = true;
                        break;
                    }
                }
                if (breakOut)
                    break;
            }
            if (breakOut)
                break;
        }
    } else {
        for(i = 0; i < redPieces.size(); i++) {
            piece = &redPieces.at(i);
            selectedPiece = *piece;
            for (int j = 0; j < 7; j++) {
                for (int k = 0; k < 9; k++) {
                    if ([self isValidMove:(float)j :(float)k]  && [self jumpsAvailable]) {
                        suggestPieceX = piece->x;
                        suggestPieceY = piece->y;
                        suggestMoveX = (float)j;
                        suggestMoveY = (float)k;
                        breakOut = true;
                        break;
                    }
                }
                if (breakOut)
                    break;
            }
            if (breakOut)
                break;
        }
    }
    selectedPiece = saveSelectedPiece;
    team0Score = tempTeam0Score;
    team1Score = tempTeam1Score;
//    std::cout << "IN SUGGEST PIECE: " << suggestPieceX << ", " << suggestPieceY << std::endl;
//    std::cout << "IN SUGGEST MOVE: " << suggestMoveX << ", " << suggestMoveY << std::endl;
    if (moves.size() != 0) return true;
    else return false;
}

-(bool) jumpsAvailable {
    moves.clear();
    checkerPiece *piece;
    checkerPiece saveSelectedPiece = selectedPiece;
    int i;
    if (!turn) {
        for(i = 0; i < grayPieces.size(); i++) {
            piece = &grayPieces.at(i);
            selectedPiece = *piece;
            if (piece->crowned) {
                [self getValidForwardMoves];
                [self getValidBackwardMoves];
                [self getValidForwardJumpMoves];
                [self getValidBackwardJumpMoves];
            } else {
                [self getValidBackwardMoves];
                [self getValidBackwardJumpMoves];
            }
        }
    } else {
        for(i = 0; i < redPieces.size(); i++) {
            piece = &redPieces.at(i);
            selectedPiece = *piece;
            if (piece->crowned) {
                [self getValidForwardMoves];
                [self getValidBackwardMoves];
                [self getValidForwardJumpMoves];
                [self getValidBackwardJumpMoves];
            } else {
                [self getValidForwardMoves];
                [self getValidForwardJumpMoves];
            }
        }
    }
    selectedPiece = saveSelectedPiece;
    if (!jump && jumpAvailable) return false;
    else return true;
}

-(void) selectedPieceJumpsAvailable {
    moves.clear();
    if (selectedPiece.crowned) {
        [self getValidForwardMoves];
        [self getValidBackwardMoves];
        [self getValidForwardJumpMoves];
        [self getValidBackwardJumpMoves];
    }
    else if (turn) {
        [self getValidForwardMoves];
        [self getValidForwardJumpMoves];
    } else {
        [self getValidBackwardMoves];
        [self getValidBackwardJumpMoves];
    }
}

-(void) selectPiece:(float) objx :(float) objy {
    checkerPiece *piece;
    std::vector<checkerPiece> *it;
    
    if(turn == 0) {
        it = &grayPieces;
    } else {
        it = &redPieces;
    }
    
    for(int i = 0; i < it->size(); i++) {
        piece = &(it->at(i));
        if(piece->x == objx && piece->y == objy) {
            if(piece->selected) {
                if (!inContinuousJump) {
                    piece->selected = false;
                    pieceSelectedIndex = -1;
                    selectedPiece.x = -1;
                    selectedPiece.y = -1;
                    selectedPiece.crowned = false;
                }
            } else if(pieceSelectedIndex == -1) {
                piece->selected = true;
                pieceSelectedIndex = i;
                selectedPiece.x = piece->x;
                selectedPiece.y = piece->y;
                selectedPiece.crowned = piece->crowned;
            }
            break;
        }
    }
}

-(int) tapOnScreen:(float)xx :(float) yy {
    int objx, objy;
    bool found;
    checkerPiece *piece;
    bool isValid = false;
    bool available = false;
    bool selectedPieceJumps = false;
    found = [calibrator findPlaceOnCheckerboard :xx :yy :&objx :&objy];
    if(found) {
//        std::cout << objx << " , " << objy << std::endl;

        [self selectPiece :objx :objy];
        
        if(pieceSelectedIndex != -1) {
            bool occupied = false;
            
            for(int i = 0; i < redPieces.size(); i++) {
                piece = &redPieces.at(i);
                if(piece->x == objx && piece->y == objy) {
                    occupied = true;
                    break;
                }
            }
            for(int i = 0; i < grayPieces.size(); i++) {
                piece = &grayPieces.at(i);
                if(piece->x == objx && piece->y == objy) {
                    occupied = true;
                    break;
                }
            }
            isValid = [self isValidMove :objx :objy];
            available = [self jumpsAvailable];
//            if (available) std::cout << "true" << std::endl;
//            else std::cout << "false" << std::endl;
            if(!occupied && isValid && available) {
                if (turn && jump) {
                    grayPieces.erase(grayPieces.begin() + erasedCheckerIndex);
                } else if (!turn && jump){
                    redPieces.erase(redPieces.begin() + erasedCheckerIndex);
                }
                switch(turn) {
                    case 0:
                        piece = &grayPieces.at(pieceSelectedIndex);
                        piece->x = objx;
                        piece->y = objy;
                        selectedPiece.x = objx;
                        selectedPiece.y = objy;
                        if (!jump && objy != 8) {
                            piece->selected = false;
                            pieceSelectedIndex = -1;
                            turn = 1;
                            inContinuousJump = false;
                        } else if (objy == 8) {
                            piece->crowned = true;
                            piece->selected = false;
                            pieceSelectedIndex = -1;
                            turn = 1;
                            inContinuousJump = false;
                            std::cout<<"GOT TO OTHER SIDE" << std::endl;
                        } else {
                            jump = false;
                            jumpAvailable = false;
                            [self selectedPieceJumpsAvailable];
                            if (!jumpAvailable) {
                                piece->selected = false;
                                pieceSelectedIndex = -1;
                                turn = 1;
                                inContinuousJump = false;
                            } else {
                                inContinuousJump = true;
                            }
                        }
                        break;
                    default:
                        piece = &redPieces.at(pieceSelectedIndex);
                        piece->x = objx;
                        piece->y = objy;
                        selectedPiece.x = objx;
                        selectedPiece.y = objy;
                        if (!jump && objy != 0) {
                            piece->selected = false;
                            pieceSelectedIndex = -1;
                            turn = 0;
                            inContinuousJump = false;
                        } else if (objy == 0) {
                            piece->crowned = true;
                            piece->selected = false;
                            pieceSelectedIndex = -1;
                            turn = 0;
                            inContinuousJump = false;
                        } else {
                            jump = false;
                            jumpAvailable = false;
                            [self selectedPieceJumpsAvailable];
                            std::cout<< selectedPiece.x << ", "<< selectedPiece.y <<std::endl;
                            if (!jumpAvailable) {
                                piece->selected = false;
                                pieceSelectedIndex = -1;
                                turn = 0;
                                inContinuousJump = false;
                            } else {
                                inContinuousJump = true;
                            }
                        }
                }
                jump = false;
                jumpAvailable = false;
            }
        }
        
    }
    if (team0Score == 11 || team1Score == 11) return 1;
    else return 0;
}

- (int) teamWon {
    if (team1Score == 11) return 1;
    else return 0;
}

- (void) newGame {
    team0Score = 0;
    team1Score = 0;
    grayPieces.clear();
    redPieces.clear();
    turn = 0;
    if(!viewRenderBuffer)
        glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    [self initializeCheckerPieces];
    [self createFramebuffer];
}

- (void) initializeCheckerPieces {
    checkerPiece gray;
    checkerPiece red;
    for(int i = 0; i < 4; i++) {
        gray.x = i*2;
        gray.y = 0;
        gray.color = 0;
        gray.selected = false;
        gray.crowned = false;
        red.x = i*2;
        red.y = 8;
        red.color = 1;
        red.selected = false;
        red.crowned = false;
        redPieces.push_back(red);
        grayPieces.push_back(gray);
    }
    
    for(int i = 0; i < 3; i++) {
        gray.x = i*2 + 1;
        gray.y = 1;
        gray.color = 0;
        gray.crowned = false;
        red.x = i*2 + 1;
        red.y = 7;
        red.color = 1;
        red.crowned = false;
        redPieces.push_back(red);
        grayPieces.push_back(gray);
    }
    
    for(int i = 0; i < 4; i++) {
        gray.x = i*2;
        gray.y = 2;
        gray.color = 0;
        gray.crowned = false;
        red.x = i*2;
        red.y = 6;
        red.color = 1;
        red.crowned = false;
        redPieces.push_back(red);
        grayPieces.push_back(gray);
    }
    [self printCheckerPieces];
}

- (void) printCheckerPieces {
    std::cout << "\n------Red Pieces------\n" << std::endl;
    for(int i = 0; i < NUM_CHECKER_PIECES; i++) {
        std::cout << "x:" << redPieces.at(i).x;
        std::cout << " y:" << redPieces.at(i).y;
        std::cout << " color:" << redPieces.at(i).color << "\n" << std::endl;
    }
    std::cout << "\n------Black Pieces------\n" << std::endl;
    for(int i = 0; i < NUM_CHECKER_PIECES; i++) {
        std::cout << "x:" << grayPieces.at(i).x;
        std::cout << " y:" << grayPieces.at(i).y;
        std::cout << " color:" << grayPieces.at(i).color << "\n" << std::endl;
    }
}

- (void) createFramebuffer {
    glGenFramebuffers(1, &viewFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, viewFrameBuffer);
    
    glGenRenderbuffers(1, &colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderBuffer);
    
    glGenRenderbuffers(1, &depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderBuffer);
    
    if(!viewRenderBuffer)
        glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
}

-(void) destroyFrameBuffer
{
    // Tear down GL
    if (viewFrameBuffer)
    {
        glDeleteFramebuffers(1, &viewFrameBuffer);
        viewFrameBuffer = 0;
    }
    
    if (colorRenderBuffer)
    {
        glDeleteRenderbuffers(1, &colorRenderBuffer);
        colorRenderBuffer = 0;
    }
    if (depthRenderBuffer)
    {
        glDeleteRenderbuffers(1, &depthRenderBuffer);
        depthRenderBuffer = 0;
    }
    if (viewRenderBuffer) {
        glDeleteRenderbuffers(1, &viewRenderBuffer);
        viewRenderBuffer = 0;
    }
}

-(bool) checkTimeStamp {
    return (clock() - prevTimeStamp > 20*1e-3*CLOCKS_PER_SEC);
}

-(bool) checkWait {
    if(wait) wait = ![self checkTimeStamp];
    return wait;
}

void drawAxes(float length)
{
    GLfloat vertice[] = {0,0,0,length,0,0};
    
    //x
    glColor4f(1, 0, 0, 1);
    glEnableClientState(GL_VERTEX_ARRAY) ;
    glVertexPointer(3, GL_FLOAT, 0, vertice);
    glLineWidth(5);
    glDrawArrays(GL_LINES, 0, 3);
    glDisableClientState(GL_VERTEX_ARRAY);
    
    //y
    glColor4f(0, 1, 0, 1);
    vertice[3] = 0; vertice[4] = length;
    glEnableClientState(GL_VERTEX_ARRAY) ;
    glVertexPointer(3, GL_FLOAT, 0, vertice);
    glLineWidth(5);
    glDrawArrays(GL_LINES, 0, 3);
    glDisableClientState(GL_VERTEX_ARRAY);
    
    //z
    glColor4f(0, 0, 1, 1);
    vertice[4] = 0; vertice[5] = length;
    glEnableClientState(GL_VERTEX_ARRAY) ;
    glVertexPointer(3, GL_FLOAT, 0, vertice);
    glLineWidth(5);
    glDrawArrays(GL_LINES, 0, 3);
    glDisableClientState(GL_VERTEX_ARRAY);
}


- (void) drawCheckerPiece: (checkerPiece) piece {
    /*
    GLfloat vertice[720];
    double z;
    
    GLfloat count = 0.00f;
    for(z = 0; z > -0.5; z-=0.05) {
        glTranslatef(0, 0, z);
        for (int i = 0; i < 720; i += 2) {
            vertice[i]   = (GLfloat)(cos(DEGREES_TO_RADIANS(i)) * 0.38) + piece.x - 0.5;
            vertice[i+1] = (GLfloat)(sin(DEGREES_TO_RADIANS(i)) * 0.38) + piece.y - 0.5;
        }
//        if(piece.selected && z == 0) {
        if(piece.selected) {
            glColor4f(0, 1 + count, 1 + count, 1.0f);
        } else if(piece.color == 0) {
            glColor4f(0.0f + count, 0.0f + count, 0.0f + count, 1.0f);
        } else {
            glColor4f(0.0f + count*2, 0.0f, 0.0f, 1.0f);
        }
        count += 0.05f;
        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(2, GL_FLOAT, 0, vertice);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 360);
        glDisableClientState(GL_VERTEX_ARRAY);
        glTranslatef(0, 0, -z);
    }
    glTranslatef(0, 0, z);
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, vertice);
    glDrawArrays(GL_TRIANGLES, 0, 360);
    glDisableClientState(GL_VERTEX_ARRAY);
    glTranslatef(0, 0, -z);
     */
    glColor4f(1, 1, 1, 1);
    GLfloat vertices[720];
    GLfloat upnormals[360*3];
    GLfloat downnormals[360*3];
    for (int i = 0; i < 720; i += 2) {
        vertices[i]   = (GLfloat)(cos(DEGREES_TO_RADIANS(-i/2)) * 0.38) + piece.x - 0.5;
        vertices[i+1] = (GLfloat)(sin(DEGREES_TO_RADIANS(-i/2)) * 0.38) + piece.y - 0.5;
        
        upnormals[i/2*3] = 0;
        upnormals[i/2*3+1] = 0;
        upnormals[i/2*3+2] = -1;
        
        downnormals[i/2*3] = 0;
        downnormals[i/2*3+1] = 0;
        downnormals[i/2*3+2] = 1;
    }
    if(piece.selected) {
        glColor4f(0, 1, 1, 1.0f);
    } else if(piece.color == 0) {
        glColor4f(0.7f, 0.7f, 0.7f, 1.0f);
    } else {
        glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
    }
    glPushMatrix();
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, downnormals);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 360);
    glPopMatrix();
    glPushMatrix();
    glTranslatef(0, 0, -0.5);
    glNormalPointer(GL_FLOAT, 0, upnormals);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 360);
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    glPopMatrix();
    
    GLfloat sides[361 * 2 * 3];
    GLfloat normals[361 * 2 * 3];
    for (int i = 0; i <= 360; i++) {
        sides[i*6]   = (GLfloat)(cos(DEGREES_TO_RADIANS(i)) * 0.38) + piece.x - 0.5;
        sides[i*6+1] = (GLfloat)(sin(DEGREES_TO_RADIANS(i)) * 0.38) + piece.y - 0.5;
        sides[i*6+2] = 0;
        
        sides[i*6+3]   = (GLfloat)(cos(DEGREES_TO_RADIANS(i)) * 0.38) + piece.x - 0.5;
        sides[i*6+4] = (GLfloat)(sin(DEGREES_TO_RADIANS(i)) * 0.38) + piece.y - 0.5;
        sides[i*6+5] = -0.5;
        
        normals[i*6] = (GLfloat)cos(DEGREES_TO_RADIANS(i));
        normals[i*6+1] = (GLfloat)sin(DEGREES_TO_RADIANS(i));
        normals[i*6+2] = 0;
        
        normals[i*6+3] = (GLfloat)cos(DEGREES_TO_RADIANS(i));
        normals[i*6+4] = (GLfloat)sin(DEGREES_TO_RADIANS(i));
        normals[i*6+5] = 0;
    }
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, sides);
    glNormalPointer(GL_FLOAT, 0, normals);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 361*2);
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
}

- (UIImage *) drawObjects: (UIImage *) image :(int*) isFound{
    GLfloat near = 1.0f, far = 1000.0f;
    
    //glClearDepthf( 1.0f );
    glEnable( GL_DEPTH_TEST );
    glEnable(GL_CULL_FACE);
    *isFound = 0;
    //set the viewport
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    glOrthof(0, (float)width, 0, (float)height, (float)near, (float)far);
    glMultMatrixf(calibrator->persMat);
    bool found = false;
    
    if(![self checkWait]) {
        found = [calibrator findChessboardCornersPlaying: image];
        
        if(!found) {
            wait = true;
            prevTimeStamp = clock();
        } else {
            
            *isFound = 1;
            
            image = [ calibrator drawTurnRectangle :turn];
            
            //  for debugging
//            image = [ calibrator drawCorners ];
            
            //use intrinsic parameters to solve pnp and rodrigues
            //this should give us extrinsic parameters
            [calibrator solvePnPRodrigues];
            
            //load in our transformed matrix
            glMatrixMode(GL_MODELVIEW);
            glEnable(GL_LIGHTING);
            glEnable(GL_LIGHT0);
            glEnable(GL_COLOR_MATERIAL);
//            // Enable lighting
//            glEnable(GL_LIGHTING);
//            
//            // Turn the first light on
//            glEnable(GL_LIGHT0);
//            
//            // Define the ambient component of the first light
//            const GLfloat light0Ambient[] = {0.1, 0.1, 0.1, 1.0};
//            glLightfv(GL_LIGHT0, GL_AMBIENT, light0Ambient);
//            
//            // Define the diffuse component of the first light
//            const GLfloat light0Diffuse[] = {0.7, 0.7, 0.7, 1.0};
//            glLightfv(GL_LIGHT0, GL_DIFFUSE, light0Diffuse);
//            
//            // Define the specular component and shininess of the first light
//            const GLfloat light0Specular[] = {0.7, 0.7, 0.7, 1.0};
//            const GLfloat light0Shininess = 0.4;
//            glLightfv(GL_LIGHT0, GL_SPECULAR, light0Specular);
//            
//            
//            // Define the position of the first light
//            const GLfloat light0Position[] = {0.0, 10.0, 10.0, 0.0};
//            glLightfv(GL_LIGHT0, GL_POSITION, light0Position);
//            
//            // Define a direction vector for the light, this one points right down the Z axis
//            const GLfloat light0Direction[] = {0.0, 0.0, -1.0};
//            glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, light0Direction);
//            
//            // Define a cutoff angle. This defines a 90° field of vision, since the cutoff
//            // is number of degrees to each side of an imaginary line drawn from the light's
//            // position along the vector supplied in GL_SPOT_DIRECTION above
//            glLightf(GL_LIGHT0, GL_SPOT_CUTOFF, 45.0);
//            glEnable(GL_COLOR_MATERIAL);
            glLoadIdentity();
            glPushMatrix();
            
            [calibrator loadMatrix];
            
            GLfloat lightPos[] = {2.5, 3.5, -2, 1};
            glLightfv(GL_LIGHT0, GL_POSITION, lightPos);
            
            for(int i = 0; i < grayPieces.size(); i++) {
                [self drawCheckerPiece :grayPieces.at(i)];
            }
            
            for(int i = 0; i < redPieces.size(); i++) {
                [self drawCheckerPiece :redPieces.at(i)];
            }
            glDisable(GL_LIGHTING);
            if ([self suggestMove] && !inContinuousJump) {
                GLfloat z = 0.0f;
                for(z = 0.0f; z > -0.5f; z-=0.01f) {
                    
                    GLfloat vertices[] = {(GLfloat)suggestPieceX - 0.5f, (GLfloat)suggestPieceY - 0.5f, z, (GLfloat)suggestMoveX - 0.5f, (GLfloat)suggestMoveY - 0.5f, z};
                    GLfloat slopeY = (GLfloat)(suggestPieceY - suggestMoveY);
                    GLfloat slopeX = (GLfloat)(suggestPieceX - suggestMoveX);
                    GLfloat arrow[9];
                    arrow[0] = (GLfloat)suggestMoveX - 0.5f;
                    arrow[1] = (GLfloat)suggestMoveY - 0.5f;
                    arrow[2] = z;
                    arrow[5] = z;
                    arrow[8] = z;
                    if (slopeX > 0.0f && slopeY > 0.0f) {
                        arrow[3] = (GLfloat)suggestMoveX - 0.5f;
                        arrow[4] = (GLfloat)suggestMoveY - 0.0f;
                        arrow[6] = (GLfloat)suggestMoveX - 0.0f;
                        arrow[7] = (GLfloat)suggestMoveY - 0.5f;
                    } else if (slopeX < 0.0f && slopeY > 0.0f) {
                        arrow[3] = (GLfloat)suggestMoveX - 1.0f;
                        arrow[4] = (GLfloat)suggestMoveY - 0.5f;
                        arrow[6] = (GLfloat)suggestMoveX - 0.5f;
                        arrow[7] = (GLfloat)suggestMoveY - 0.0f;
                    } else if (slopeX > 0.0f && slopeY < 0.0f) {
                        arrow[3] = (GLfloat)suggestMoveX - 0.0f;
                        arrow[4] = (GLfloat)suggestMoveY - 0.5f;
                        arrow[6] = (GLfloat)suggestMoveX - 0.5f;
                        arrow[7] = (GLfloat)suggestMoveY - 1.0f;
                    } else {
                        arrow[3] = (GLfloat)suggestMoveX - 0.5f;
                        arrow[4] = (GLfloat)suggestMoveY - 1.0f;
                        arrow[6] = (GLfloat)suggestMoveX - 1.0f;
                        arrow[7] = (GLfloat)suggestMoveY - 0.5f;
                    }
                    glColor4f(1.f, 1.0f, 0.0f, 1.0f);
                    glEnableClientState(GL_VERTEX_ARRAY) ;
                    glVertexPointer(3, GL_FLOAT, 0, vertices);
                    glLineWidth(5);
                    glVertexPointer(3, GL_FLOAT, 0, arrow);
                    glDrawArrays(GL_TRIANGLES, 0, 3);
                    glVertexPointer(3, GL_FLOAT, 0, vertices);
                    glDrawArrays(GL_LINES, 0, 3);
                    glDisableClientState(GL_VERTEX_ARRAY);
                }
            }
//            drawAxes(2);
            
            
            [context presentRenderbuffer:GL_RENDERBUFFER];
            glPopMatrix();
        }
    }
    return image;
}


-(void) setView: (GLKView *) _view {
    view = (GLKView *)_view;
    std::cout << "\n\n\nsetting view for opengl\n\n\n\n" << std::endl;
}

-(void) initOpenGL: (void*)opencv {
    std::cout << "\n\n\ninitializing openGL\n\n\n" << std::endl;
    calibrator = (__bridge OpenCVWrapper *)opencv;
}

- (void)dealloc {
    if (context == [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext: nil];
    }
    effect = nil;
}


@end
