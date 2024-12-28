import matplotlib.pyplot as plt
import numpy as np

# Data
categories = ['Category 1', 'Category 2', 'Category 3', 'Category 4']
series1 = [4, 7, 1, 8]
series2 = [5, 6, 3, 5]
series3 = [6, 5, 4, 6]

# Number of categories and series
x = np.arange(len(categories))  # The label locations
width = 0.25  # The width of the bars

# Create the plot
fig, ax = plt.subplots(figsize=(10, 6))

# Plot each series
bars1 = ax.bar(x - width, series1, width, label='Series 1')
bars2 = ax.bar(x, series2, width, label='Series 2')
bars3 = ax.bar(x + width, series3, width, label='Series 3')

# Add labels, title, and legend
ax.set_xlabel('Matrix dimensions(x*x)')
ax.set_ylabel('Time (s)')
ax.set_title('Title')
ax.set_xticks(x)
ax.set_xticklabels(categories)
ax.legend()

# Display the plot
plt.tight_layout()
plt.show()
