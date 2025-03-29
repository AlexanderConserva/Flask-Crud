# Use Python 3.9 as the base image
FROM python:3.9

# Set the working directory inside the container
WORKDIR /app

# Copy the project files into the container
COPY . .

# Upgrade pip and install dependencies
RUN pip install --upgrade pip && pip install -r requirements.txt

# Set environment variables for Flask
ENV FLASK_APP=crudapp.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_ENV=production

# Expose port 80
EXPOSE 80

# Run database migrations before starting the app
RUN flask db init || true
RUN flask db migrate -m "entries table" || true
RUN flask db upgrade || true

# Run the Flask application
CMD ["flask", "run", "--host=0.0.0.0", "--port=80"]