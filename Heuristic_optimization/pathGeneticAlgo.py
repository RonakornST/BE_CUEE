import random
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

# Parameters
POPULATION_SIZE = 30
MUTATION_RATE = 0.1
NUM_GENERATIONS = 1000
GRID_SIZE = (10, 10)

# Start and goal positions
start = (0, 0)
goal = (9, 9)

# Obstacles in the grid
obstacles = {(3, 3), (3, 4), (3, 5), (4, 3), (5, 3)}

# Define movements (Up, Down, Left, Right)
moves = [(0, 1), (0, -1), (1, 0), (-1, 0)]

# Generate a random path
def generate_path():
    return [random.choice(moves) for _ in range(15)]

# Evaluate path fitness based on proximity to the goal and obstacle collisions
def evaluate_path(path):
    position = start
    fitness = 50  # Start with a base fitness score to ensure non-negative fitness

    for move in path:
        next_position = (position[0] + move[0], position[1] + move[1])

        # Check if within grid bounds
        if 0 <= next_position[0] < GRID_SIZE[0] and 0 <= next_position[1] < GRID_SIZE[1]:
            position = next_position

            # Penalty if on obstacle
            if position in obstacles:
                fitness -= 10

            # Reward proximity to the goal
            fitness -= abs(goal[0] - position[0]) + abs(goal[1] - position[1])
        else:
            fitness -= 15  # Penalty for going out of bounds

    # Reward reaching the goal with a high bonus
    if position == goal:
        fitness += 200

    return max(fitness, 1)  # Ensure fitness is at least 1 to avoid zero-weight issues


# Selection function based on fitness
def select(population):
    weights = [evaluate_path(path) for path in population]
    return random.choices(population, weights=weights, k=POPULATION_SIZE)

# Crossover between two parents
def crossover(parent1, parent2):
    crossover_point = random.randint(0, len(parent1) - 1)
    return parent1[:crossover_point] + parent2[crossover_point:]

# Mutate a path with a given mutation rate
def mutate(path):
    if random.random() < MUTATION_RATE:
        index = random.randint(0, len(path) - 1)
        path[index] = random.choice(moves)
    return path

# Initialize population
population = [generate_path() for _ in range(POPULATION_SIZE)]
best_paths = []  # Track best path in each generation

# Visualization setup
fig, ax = plt.subplots()
ax.set_xlim(-1, GRID_SIZE[0])
ax.set_ylim(-1, GRID_SIZE[1])
ax.set_xticks(np.arange(-0.5, GRID_SIZE[0], 1))
ax.set_yticks(np.arange(-0.5, GRID_SIZE[1], 1))
ax.grid(True)

# Function to plot the grid with obstacles, start, and goal
def plot_grid(best_path, gen):
    ax.clear()
    ax.set_xticks(np.arange(-0.5, GRID_SIZE[0], 1))
    ax.set_yticks(np.arange(-0.5, GRID_SIZE[1], 1))
    ax.grid(True)

    # Plot obstacles
    for obs in obstacles:
        ax.add_patch(plt.Rectangle(obs, 1, 1, color="black"))

    # Plot start and goal points
    ax.plot(*start, "go", label="Start")  # Start in green
    ax.plot(*goal, "ro", label="Goal")    # Goal in red

    # Plot the best path found so far
    position = start
    for move in best_path:
        next_position = (position[0] + move[0], position[1] + move[1])
        if 0 <= next_position[0] < GRID_SIZE[0] and 0 <= next_position[1] < GRID_SIZE[1]:
            ax.plot(*next_position, "bo")  # Path in blue
            position = next_position

    # Add generation info
    ax.set_title(f"Generation {gen+1}")
    ax.legend()

# Function to update the plot at each generation
# Updated update function to display every 10 generations
def update(gen):
    global population

    # Evaluate and select the best paths
    population = select(population)

    # Generate next generation through crossover and mutation
    next_generation = []
    for i in range(0, POPULATION_SIZE, 2):
        parent1, parent2 = population[i], population[(i + 1) % POPULATION_SIZE]
        child1, child2 = crossover(parent1, parent2), crossover(parent2, parent1)
        next_generation.append(mutate(child1))
        next_generation.append(mutate(child2))

    population = next_generation

    # Track the best path in the population
    best_path = max(population, key=evaluate_path)
    best_paths.append(best_path)

    # Plot every 10 generations
    if gen % 10 == 0:
        plot_grid(best_path, gen)

    # Stop early if goal is reached
    if evaluate_path(best_path) >= 100:
        anim.event_source.stop()

# Run the animation with modified update interval
anim = FuncAnimation(fig, update, frames=NUM_GENERATIONS, repeat=False)
plt.show()

# Run the animation
anim = FuncAnimation(fig, update, frames=NUM_GENERATIONS, repeat=False)
plt.show()
